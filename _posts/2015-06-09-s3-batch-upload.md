---
layout: post
title: "Batch image uploading with Amazon S3 and RethinkDB"
author: Ryan Paul
author_github: segphault
hero_image: 2015-06-09-s3-batch-upload.png
---

Many applications provide a way to upload images, offering users a
convenient way to share photos and other rich content. Driven in part by
the ubiquity of built-in cameras on smartphones, image uploading is
practically expected in any application with social or messaging
features. Fortunately, cloud-based hosting services like Amazon's S3 can
shoulder the burden of storing large amounts of user-generated content.

Of course, you can also use RethinkDB to store thumbnails, important image
metadata, and application-specific details about your S3 uploads. In this
tutorial, I'll demonstrate how to handle batch image uploading with Amazon
S3 and RethinkDB. The demo application puts full-sized images in an Amazon
S3 bucket while using RethinkDB to store image metadata and small
thumbnails. I'm also going to show you some useful techniques for building
a good frontend image uploading experience on the web, featuring
drag-and-drop support and a live progress bar.

<!--more-->

# Process multipart form data

I built my backend with Node.js and Express. In order to accommodate batch
image uploads, I made my application support multipart form data. There
are a number of third-party libraries that offer the requisite
functionality, but I'm partial to [multiparty][].

The following code demonstrates how to use Express and multiparty to set
up an API endpoint for file uploads:

```javascript
var express = require("express");
var multiparty = require("multiparty");

var app = express();
app.listen(8095, function() {
  console.log("Listening on port " + 8095);
});

app.post("/upload", function(req, res) {
  new multiparty.Form().parse(req, function(err, fields, files) {
    ...

    files.images.forEach(function(file) {
      console.log(file.path, file.originalFilename);
    });

    ...
  });
});
```

The `parse` method processes multipart form data attached to a request.
When the user invokes the `parse` method with a callback, the framework
will automatically cache the uploaded files to disk for easy access. As
you will see later, the application will have to manually purge the
temporary files when they are no longer needed.

It's worth noting that multiparty also provides an event-based API that
exposes raw streams instead of relying on temporary files. Although the
cache-based approach is simpler for this particular demo, you might want
to consider a more idiomatic streaming model for other usage scenarios.

In the example above, the `files` parameter of the `parse` callback
contains an object with all of the file-bearing form fields. You can
iterate over the files and access each one. File objects have several
useful properties:

* `path`: the location where multiparty cached the uploaded file on the local filesystem
* `originalFilename`: the name and extension that came with the original file uploaded by the user

# Upload and resize images

Amazon provides a comprehensive AWS SDK for Node.js, which makes it easy
to interact with services like S3. The SDK includes a convenience method
for performing S3 uploads, with support for consuming Node.js streams. The
following example shows how to upload files:

```javascript
files.images.forEach(function(file) {
  s3.upload({
    Key: file.originalFilename,
    Bucket: "rethinkdb-demo",
    ACL:"public-read",
    Body: fs.createReadStream(file.path)
  }, function(err, output) {
    console.log("Finished uploading:", output.Location);
  });
});
```

To create image thumbnails, I used the `resize` command from [`gm`][gm],
Node.js bindings for the [GraphicsMagick][GraphicsMagick] library. The
`gm` library provides a number of image transformation commands that the
user can chain together in sequence. The `gm` library also includes a
`toBuffer` method that outputs the transformed image as a Node.js `Buffer`
object, suitable for insertion into the database.

Although a specific example is beyond the scope of this tutorial, it's
worth noting that `gm` offers some functions for metadata
extraction--which could be useful in cases where you wan to store
additional information about an image in a database record for later use.

RethinkDB's Node.js client driver automatically treats `Buffer` objects as
binary data, so there's no need to explicitly use ReQL's
[`r.binary`][binary] command. The following example shows how to resize a
file and generate a `Buffer` as output:

```javascript
gm(file.path).resize(100).toBuffer(function(err, buffer) {
  // ... insert `buffer` into the database
});
```

# Use Promises to control the flow of asynchronous operations

Uploading and resizing individual files is a fairly straightforward
undertaking, but now the asynchronous nature of Node.js makes it difficult
to put everything together. The application needs to upload the files,
generate thumbnails, and then perform a ReQL `insert` query that
incorporates all of that output.

Fortunately, Promises provide a useful way to control the flow of
execution and aggregate the output of the asynchronous operations. I was
able to tame the beast by taking advantage of some of the advanced
features included in the [`bluebird` Promise library][bluebird]:

```javascript
var express = require("express");
var shortid = require("shortid");
var bluebird = require("bluebird");
var multiparty = require("multiparty");
var r = require("rethinkdb");
var aws = require("aws-sdk");
var gm = require("gm");
var fs = require("fs");

// Configure the AWS SDK with my access credentials
aws.config.update({
  accessKeyId: "XXXXXXXXXXXXXXXXXXXX",
  secretAccessKey: "XXXXXXXXXXXXXXXXXXXX"
});

// Create a Promise-based wrapper around S3 APIS
var s3 = bluebird.promisifyAll(new aws.S3());

// Initialize Express application
var app = express();
app.listen(8095, function() {
  console.log("Listening on port " + 8095);
});

// Serve static files on the "/public" route
app.use(express.static(__dirname + "/public"));

// Wrapper that adds Promise-based interface to the
// GraphicsMagick library's image resizing function.
// It outputs a Buffer, which will work with ReQL's r.binary
var resizeImg = bluebird.promisify(function(input, size, cb) {
  gm(input).resize(size).toBuffer(function(err, buffer) {
    if (err) cb(err); else cb(null, buffer);
  });
});

// Handler for image upload POST requests
app.post("/upload", function(req, res) {
  // Parse multipart form data included with the request
  new multiparty.Form().parse(req, function(err, fields, files) {

    // Iterate over files and return an array of Promises 
    // that will concurrently resize and upload the images
    var operations = files.images.map(function(file) {
      // Generate a short unique ID for each file
      var id = shortid.generate();

      // Return a Promise that incorporates concurrent
      // image uploading and resizing, while also
      // passing some useful values along the chain
      return bluebird.join(id, file,
        resizeImg(file.path, 100),
        s3.uploadAsync({
          Key: id + "_" + file.originalFilename,
          Bucket: "rethinkdb-demos",
          ACL:"public-read",
          Body: fs.createReadStream(file.path)
        }));
    });

    // Connect to RethinkDB and simultaneously perform
    // the upload/resize operations
    bluebird.join(r.connect(), bluebird.all(operations),
    function(conn, images) {
      // Iterate over the data returned by the upload/resize
      // and replace that with a record that has only the
      // properties we want to put in the database
      var items = images.map(function(i) {
        // Delete the cached temporary file
        fs.unlink(i[1].path);
        return {id: i[0], thumb: i[2],
          url: i[3].Location, file: i[1].originalFilename};
      });

      // Insert the database records for the new images
      // and close the DB connection when finished
      return r.table("graphics").insert(items, {returnChanges: true})
        ("changes")("new_val").without("thumb").run(conn)
      .finally(function() { conn.close(); });
    })
    .then(function(output) {
      // Pass the new records (without the binary thumbnail)
      // to the end user as JSON
      console.log("Completed upload:", output);
      res.json({success: true, images: output});
    })
    .error(function(e) {
      // Handle any errors or failures
      console.log("Failed to upload:", e);
      res.status(400).json({success: false, err: e});
    });
  });
});

```

I used Bluebird's `promisify` feature to create Promise-based wrappers
around the desired `gm` and S3 library functions. Next, I used a `map`
operation to iterate over all of the uploaded files, returning an array of
Promises that perform concurrent image uploading and resizing for each
item. When the application passes that array to `bluebird.all`, I get a
Promise that waits for those operations to complete and then provides all
of the output. From there, I took the aggregated output and used it to
craft an array of records to insert into RethinkDB.

I took advantage of the `returnChanges` option so that the ReQL insert
query can also retrieve the new records. The ReQL query strips the binary
thumbnail data from the output, returning the resulting JSON structure as
the response to the user's HTTP POST request. The application returns the
JSON data in order to ensures that frontend will be able to display the
images when the upload is complete.

# Serve images from RethinkDB with Express

Now that the full-sized images are in S3 and the corresponding thumbnail
is stored in a RethinkDB document, I want to present those on the
frontend. I uploaded the image to S3 with the `public-read` permission,
which means that I can load it from a conventional URL that is hosted on
Amazon's infrastructure.

Accessing the image in the database, however, requires a little bit more
work. I created an Express URL route that dynamically fetches an image
from the database and serves it to the user:

```
app.get("/thumb/:id", function(req, res) {
  r.connect(config.db).then(function(conn) {
    return r.table("graphics").get(req.params.id).run(conn)
      .finally(function() { conn.close(); });
  })
  .then(function(output) {
    if (!output) return res.status(404).json({err: "Not found"});
    res.write(output.thumb);
    res.end();
   });
});
```

The above `GET` request handler takes the ID provided in the URL path and
retrieves the corresponding RethinkDB document from the `graphics` table.
If the document exists, the application will take the contents of its
`thumb` property and serve the binary data directly to the user. This
approach makes it possible to display the thumbnail with a conventional
HTML `img` tag that references the URL route of a thumbnail in its `src`
attribute.

# Build a web frontend for batch uploads

I took advantage of several useful HTML5 features when I built the
accompanying browser-based frontend for my batch image uploader. It uses
native drag-and-drop, making it possible for the user to drag in files
from their file manager or desktop. My frontend also uses a native
progress bar element to display the status of the batch upload.

I used the following HTML markup to set up the form and the `div`
container that will receive file drop events:

```html
<div id="dropsite">
  <h1 id="instruction">Drop files here</h1>
  <form id="upload" action="/upload" method="POST" enctype="multipart/form-data">
    <input type="file" id="fileselect" name="images" multiple="multiple" />
  </form>
  <progress id="progress" max="100" value="0"></progress>
</div>

<button id="submit" onclick="uploadFiles()">Upload</button>
```

I attached drag-and-drop event handlers to the `div` tag, programming it
to pass any dropped files to the file selection `input` tag. The advantage
of this approach is that it gives users the option of using the
conventional file selection dialog as an alternative to drag-and-drop.

```javascript
var dropsite = document.getElementById("dropsite");

dropsite.ondragover = function() { return false; };
dropsite.ondragend = function() { return false; };

dropsite.ondrop = function(ev) {
  ev.stopPropagation(); ev.preventDefault();
  document.getElementById("fileselect").files = ev.dataTransfer.files;
  return false;
}
```

Instead of standard form submission, I programmed the page to perform the
image upload operation in the background with an XHR. The submit button
calls an `uploadFiles` function that sets up the XHR and performs the
upload:

```javascript
function uploadFiles() {
  var req = new XMLHttpRequest();

  req.onload = function() {
    console.log(JSON.parse(req.response).images);
    document.getElementById("progress").value = 0
  };

  req.upload.onprogress = function(ev) {
    document.getElementById("progress").value =
      (ev.loaded / ev.total) * 100;
  };

  req.open("POST", "/upload", true);
  req.send(new FormData(document.getElementById("upload")));
}
```

The function instantiates a `FormData` object and populates it with the
contents of the upload form, thereby attaching the files from the file
selection input to the request in proper multipart format. I attached a
callback to the `upload.onprogress` event so that I can regularly update
the native progress bar throughout the upload process. It compares the
number of uploaded bytes against the number of total bytes in order to
compute the completion percentage.

When the upload completes, the server returns a JSON object with metadata
about each image. You can use that metadata to append the new images to
the page. In my demo, I accomplished that step with a simple handlebars
template:

{% raw %}
```html
<script id="template" type="text/x-handlebars-template">
  <div class="thumb">
    <a href="{{url}}"><img src="/thumb/{{id}}"></a>
  </div>
</script>
```
{% endraw %}

```javascript
var template = Handlebars.compile(document.getElementById("template").innerHTML);

...

function addImages(items) {
  for (var i in items)
    document.getElementById("thumbs").innerHTML += template(items[i]);
}
```

To insert the new images into the page, I just take the JSON output of the
XHR and pass it to the `addImages` function described above.

# Next steps

Now you know how to add batch image uploads to your own RethinkDB
application. In addition to the browser-based web frontend described in
this article, you could also build your own native mobile frontends that
rely on the same backend URL endpoints.

You can find the [complete source code][ghlink] for this demo application
on GitHub. [Install RethinkDB][install] and try it yourself today. You can
also follow our [ten-minute quickstart guide][10min] to learn more about
RethinkDB.

[multiparty]: https://github.com/andrewrk/node-multiparty
[gm]: http://aheckmann.github.io/gm/
[GraphicsMagick]: http://www.graphicsmagick.org/
[binary]: http://rethinkdb.com/api/javascript/binary/
[bluebird]: https://github.com/petkaantonov/bluebird
[install]: http://rethinkdb.com/docs/install/
[ghlink]: https://github.com/rethinkdb/s3-batch-upload
[10min]: http://rethinkdb.com/docs/guide

