---
layout: post
title: "CatThink: see the cats of Instagram in realtime with RethinkDB and Socket.io"
author: Ryan Paul
author_github: segphault
hero_image: 2014-11-05-cat-instagram.png
---

Modern frameworks and standards make it easy for developers to build web
applications that support realtime updates. You can push the latest data to
your users, offering a seamless experience that results in higher engagement
and better usability. With the right architecture on the backend, you can put
polling out to pasture and liberate your users from the tyranny of the refresh
button.

In this tutorial, I'll show you how I built a realtime Instagram client for the
web. The application, which is called CatThink, displays a live feed of new
Instagram pictures that have the `#catsofinstagram` tag. Why cats of Instagram?
Because it's one of the photo service's most popular and beloved tags. People
on the internet really, really like cats. Or maybe we just think we do because
our feline companions have [reprogrammed us with brain parasites][1].
<!--more-->

[1]: http://en.wikipedia.org/wiki/Toxoplasmosis

The cat pictures appear in real time, as they are posted by their respective
users. CatThink shows the pictures in a grid, accompanied by captions and other
relevant metadata. In a secondary view, the application uses geolocation info
to plot the cat pictures on a map.

<img src="/assets/images/posts/2014-11-05-cat-grid.png">

# CatThink's architecture

The CatThink backend is built with Node.js and Express on top of RethinkDB. The
HTML frontend uses jQuery and Handlebars to display the latest cat pictures.
The frontend map view is built with [Leaflet][], a popular map library that
uses tiles from OpenStreetMap. The application uses [Socket.io][] to facilitate
communication between the frontend and backend.

[Leaflet]: http://leafletjs.com/
[Socket.io]: http://socket.io/

CatThink takes advantage of Instagram's realtime APIs to determine when new
images are available. Instagram offers a webhook-based system that allows a
backend application to subscribe to updates on a given tag. When there are new
posts with the `#catsofinstagram` tag, Instagram's servers send an HTTP POST
request to a callback URL on your server. The POST request doesn't actually
include the new content, it just includes a timestamp and the name of the
updated tag---your application has to fetch the new records using Instagram's
conventional REST API endpoints.

When the CatThink backend receives a POST request from Instagram, it performs a
RethinkDB query that uses the `r.http` command to fetch the latest records from
the Instagram REST API and add them directly to the database. The database
itself performs the HTTP GET request and parses the returned data.

Because the operation is performed entirely with ReQL, the backend application
isn't responsible for fetching or processing any of the new Instagram pictures.
Of course, the backend application will still need to know about new cat
pictures so that it can send them to the frontend with Socket.io. CatThink
accomplishes that with [changefeeds][], a RethinkDB feature that lets
applications subscribe to changes on a table.  Whenever the database adds,
removes, or changes a document in the table, it will notify subscribed
applications.

[changefeeds]: rethinkdb.com/docs/changefeeds/

CatThink subscribes to a changefeed on the table where the cat records are
stored. Whenever the database inserts a new cat record, CatThink receives the
data through the changefeed and then broadcasts it to all of the Socket.io
connections.

# Connect to the Instagram realtime API

To use the Instagram API, you will have to [register an application key][2] on
the Instagram developer site. You will need to use the client ID and client
secret provided by Instagram in order to hit the API endpoints. You don't need
to configure the key with a redirect URI, however, as you won't be using
authentication.

[2]: http://instagram.com/developer/clients/manage/

To subscribe to a tag with Instagram's realtime API, make an HTTP POST request
to the `api.instagram.com/v1/subscriptions/`. In the form data attached to the
request, you will need to provide the application key data, the name of the
tag, a verification token, and the callback URL where you want Instagram to
send new data. The verification token is an arbitrary string that Instagram
will pass back to your application when it hits the callback URL.

Note: the callback URL that you provide to Instagram must be
publicly-accessible to outside networks. For development purposes, it can be
helpful to use a tool like [ngrok][] that exposes a local port to the public
internet.

[ngrok]: https://ngrok.com/

In CatThink, I use the [request][] library to perform the initial request to
the Instagram server:

[request]: https://www.npmjs.org/package/request

```javascript
var params = {
  client_id: "XXXXXXXXXXXXXXXXXXXXXXXXX",
  client_secret: "XXXXXXXXXXXXXXXXXXXXXXXXX",
  verify_token: "somestring",
  object: "tag", aspect: "media",
  object_id: "catsofinstagram",
  callback_url: "http://mycatapp.ngrok.com/publish/photo"
};

request.post({url: api + "subscriptions", form: params},
  function(err, response, body) {
    if (err) console.log("Failed to subscribe:", err);
    else console.log("Successfully subscribed.");
});
```

If the subscription API call is properly formed, Instagram will immediately
attempt to make an HTTP GET request at the callback URL. It will send several
query parameters, including the verification token and a challenge key. In
order to complete the subscription, you have to make the GET request return the
provided challenge key. With Express, create a GET handler for the callback
URL:

```javascript
app.get("/publish/photo", function(req, res) {
  if (req.param("hub.verify_token") == "somestring")
    res.send(req.param("hub.challenge"));
  else res.status(500).json({err: "Verify token incorrect"});
});
```

# Fetch the latest cats

The next step is to implement the POST handler for the callback URL. When
Instagram sends the application a POST request to inform it of new content on
the subscribed tag, it includes several bits of information in the request
body:

```javascript
[{
        "changed_aspect": "media",
        "object": "tag",
        "object_id": "catsofinstagram",
        "time": 1414995025,
        "subscription_id": 14185203,
        "data": {}
}]
```

The `object_id` property is obviously the name of the subscribed tag. The
`time` property is a UNIX timestamp that reflects when the event occurred. The
`subscription_id` property is a value that uniquely identifies the individual
subscription.

Whenever the application receives a POST request at the callback URL, it will
tell the database to fetch the latest cat records from Instagram's REST API.
The application also provides a response so that Instagram knows that the POST
request didn't fail. If the POST requests that Instagram sends to the
application start to fail, Instagram will automatically taper off requests and
eventually cancel the tag subscription.


```javascript
app.post("/publish/photo", function(req, res) {
  var update = req.body[0];
  res.json({success: true, kind: update.object});

  if (update.time - lastUpdate < 1) return;
  lastUpdate = update.time;

  var path = "https://api.instagram.com/v1/tags/" +
             "catsofinstagram/media/recent?client_id=" +
             instagramClientId;


  r.connect(config.database).then(function(conn) {
    this.conn = conn;
    return r.table("instacat").insert(
      r.http(path)("data").merge(function(item) {
        return {
          time: r.now(),
          place: r.point(
            item("location")("longitude"),
            item("location")("latitude")).default(null)
        }
      })).run(conn)
  })
  .error(function(err) { console.log("Failure:", err); })
  .finally(function() {
    if (this.conn)
      this.conn.close();
  });
});
```

In the code above, the ReQL query uses the `r.point` command in a `merge`
operation to turn the geographical coordinates for each cat photo into a native
[geolocation point object][geo]. That's not used in the application, but it
might be useful later if you wanted to create a geospatial index and query for
cat pictures based on location.

[geo]: /docs/geo-support

In order to avoid hitting the Instagram API limit, the application checks the
timestamp provided with each POST request and does some basic throttling to
ensure that new cat records aren't typically going to be fetched more than once
per second.

The `path` variable in the handler code is the URL of the Instagram REST API
endpoint that the application uses to fetch the latest cat. In this example,
the "catsofinstagram" tag is hard-coded into the URL path. It's worth noting,
however, that you could use the name of the subscribed tag from the `object_id`
property if you wanted to use the same POST handler to deal with multiple tag
subscriptions.

## Verify the request origin

In cases where you rely on the `object_id` property, you'd probably also want
to validate the source of the POST request to make sure that it actually came
from Instagram. If you don't verify the origin, somebody might figure out your
URL endpoint and send you malicious POST requests that include an `object_id`
for a rogue tag that you don't want to appear in your application. You wouldn't
want some nefarious anti-cat vigilante to trick your application into showing
dogs, for example.

Every POST request from Instagram will have an `X-Hub-Signature` header with a
hash that you can validate using your secret key and the request body. The
`bodyParser` middleware provides a `verify` option that is specifically
intended for such purposes:

```javascript
app.use("/publish/photo", bodyParser.json({
  verify: function(req, res, buf) {
    var hmac = crypto.createHmac("sha1", "XXXXXXXXXXXXXXX");
    var hash = hmac.update(buf).digest("hex");

    if (req.header("X-Hub-Signature") == hash)
      req.validOrigin = true;
  }
}));
```

At the beginning of your POST handler, you would simply check the value of
`req.validOrigin` and make sure that it's `true` before continuing.

# Use changefeeds to handle new cats

The CatThink backend uses RethinkDB changefeeds to detect when the database
adds new records to the cat table. In a ReQL query, the `changes` command
returns a cursor that exposes every modification that is made to the specified
table. The following code shows how to consume the data emitted by the
changefeed and broadcast each new item with Socket.io:

```javascript
r.table("instacat").changes().run(this.conn).then(function(cursor) {
  cursor.each(function(err, item) {
    if (item && item.new_val)
      io.sockets.emit("cat", item.new_val);
  });
})
.error(function(err) {
  console.log("Error:", err);
});
```

CatThink broadcasts every cat to every user, so you don't need to worry about
tracking individual Socket.io connections or routing messages to the right
users.

In addition to broadcasting new cats, it's also a good idea to pass the user a
modest backlog of cats when they first establish their connection with the
server so that their initial view of the application is populated with some
data. In a Socket.io connection event handler, CatThink performs a ReQL query
that fetches the 60 most recent cats and then sends the result set back to the
user:

```javascript
io.sockets.on("connection", function(socket) {
  r.connect(config.database).then(function(conn) {
    this.conn = conn;
    return r.table("instacat").orderBy({index: r.desc("time")})
            .limit(60).run(conn)
  })
  .then(function(cursor) { return cursor.toArray(); })
  .then(function(result) {
    socket.emit("recent", result);
  })
  .error(function(err) { console.log("Failure:", err); })
  .finally(function() {
    if (this.conn)
      this.conn.close();
  });
});
```

# Implement the frontend

The CatThink frontend has a very simple user interface: It displays the grid of
cats and the accompanying map view. A full-blown JavaScript MVC framework would
likely be overkill, so it uses a pretty light dependency stack. It uses Leaflet
for the map, jQuery for the UI logic, and [Handlebars][] templating to generate
the markup for each new cat picture.

[Handlebars]: http://handlebarsjs.com/

After some initial setup for the tab switching and map view, the bulk of the
frontend code is housed in a single `addCat` function that applies the template
to the cat data, inserts the new markup into the grid, and then creates the
location marker for cats with geolocation data:

```javascript
var map = L.map("map").setView([0, 0], 2);
map.addLayer(L.tileLayer(mapTiles, {attribution: mapAttrib}));

var template = Handlebars.compile($("#cat-template").html());
var markers = [];

function addCat(cat) {
  cat.date = moment.unix(cat.created_time).format("MMM DD, h:mm a");
  $("#cats").prepend(template(cat));

  if (cat.place) {
    var count = markers.unshift(L.marker(L.latLng(
        cat.place.coordinates[1],
        cat.place.coordinates[0])));

    map.addLayer(markers[0]);
    markers[0].bindPopup(
        "<img src=\"" + cat.images.thumbnail.url + "\">",
        {minWidth: 150, minHeight: 150});

    markers[0].openPopup();

    if (count > 100)
      map.removeLayer(markers.pop());
  }
}
```

The map markers are stored in an array so that the application can easily
remove old markers as it adds new ones. The marker cap is set to 100 in the
code above, but you could likely raise it considerably if desired. It's
important to have some kind of cap, however, because Leaflet can sometimes
exhibit odd behavior if you have too many.

<img src="/assets/images/posts/2014-11-05-cat-map.png">

The Handlebars template that the application applies to the cat data is
embedded in the HTML page itself, using a `script` tag with a custom type:

{% raw %}
```
<script id="cat-template" type="text/x-handlebars-template">
  <div class="cat">
    <div class="user">{{user.full_name}}</div>
    <div class="meta">
      <div class="time">Posted at {{date}}</div>
      <div class="caption">{{caption.text}}</div>
    </div>
    <img class="thumb" src="{{images.low_resolution.url}}">
  </div>
</script>
```
{% endraw %}

The last piece of the puzzle is implementing Socket.io on the client side. The
application needs to establish a Socket.io connection with the server and then
provide event handlers for the backlog and new cats. Both handlers will simply
use the `addCat` function shown above.

```javascript
var socket = io.connect();

socket.on("cat", addCat);
socket.on("recent", function(data) {
  data.reverse().forEach(addCat);
});
```

The handler for the "cat" event receives a single cat object, which is
immediately passed into the `addCat` function. The  handler for the "recent"
event receives an array of cat objects from the server. It reverses the array
before adding the cats so that the images will display in reverse-chronological
order, consistent with how they are added in real time.

# Next steps

Although CatThink is not particularly complex, changefeeds helped to simplify
the application and reduce the total amount of necessary code. Without
changefeeds, the CatThink backend would have to fetch, parse, and process all
of the cat records on its own instead of offloading that work to the database
with a simple ReQL query.

In larger realtime applications, changefeeds can potentially offer more
profound architectural advantages. You can increase the modularity of your
application by decoupling the parts that handle and process data from the parts
that convey updates to the frontend. There are also cases where you can use
changefeeds to eliminate the need for dedicated message queue systems.

In the current version of RethinkDB, changefeeds offer a useful way to monitor
changes on individual tables. In future versions, changefeeds will support a
richer set of capabilities. Users will be able to monitor filtered data sets
and detect change events on complex aggregations, like a player leader board or
realtime moving averages. You can look forward to seeing the first round of new
changefeed features in an upcoming release.

[Install RethinkDB][install] and try the [ten-minute guide][guide] to
experience the database in action.

[install]: /docs/install/
[guide]: /docs/guide/javascript/

For additional information, you can refer to:

* The RethinkDB [changefeed documentation][3]
* The [`changes` command page][4] in the ReQL API reference
* The complete [CatThink source code][5] on GitHub
* Instagram's [realtime API documentation][6]
* The official [Socket.io website][7]

[3]: /docs/changefeeds
[4]: /api/ruby/changes
[5]: https://github.com/rethinkdb/cats-of-instagram
[6]: http://instagram.com/developer/realtime/
[7]: http://socket.io/
