---
layout: post
title: "Hands-on with deepstream.io: build realtime apps with less backend code"
author: Ryan Paul
author_github: segphault
---

The developers at [Hoxton One][] recently released [deepstream][], a new
open source framework for realtime web application development. The
framework, which is built with [Node.js][] and [Engine.io][], helps
developers build frontend web applications that perform realtime updates
while requiring minimal backend code.

The deepstream framework comes with a client library for the browser that
lets the developer create and update data records on the fly. The client
library relays updates to the server, which propagates the new data to
other subscribed clients. The developer doesn't have to write any
specialized backend code to handle the changes or propagate the events.

The developers behind deepstream provide an optional RethinkDB data
connector, which lets the framework use RethinkDB for data persistence. As
the frontend client updates records, the deepstream backend stores the
changes in RethinkDB documents.

<!--more-->

To get a hands-on look at deepstream, I used the framework to build a very
simple todo list application. In this blog post, I'll show you my demo app
and demonstrate how to configure deepstream to use the RethinkDB storage
connector.

# Configure deepstream to use RethinkDB

On the backend, I set up a deepstream server in Node.js. I installed the
[`deepstream.io`][npmframework] and
[`deepstream.io-storage-rethinkdb`][npmstorage] packages from NPM to get
the underlying framework and the RethinkDB storage connector. Next, I
wrote the following script to configure the server:

```javascript
var DSServer = require("deepstream.io");
var DSRethinkConnector = require("deepstream.io-storage-rethinkdb");

// Setup the deepstream server
var server = new DSServer();
server.set("host", "localhost");
server.set("port", 6020);

// Setup the RethinkDB storage connector
server.set("storage", new DSRethinkConnector({
    port: 28015,
    host: "localhost",
    splitChar: "/",
    defaultTable: "dsdemo"
}));

// Run the server
server.start();
```

If your RethinkDB cluster isn't running on the same server as the
application, be sure to specify the correct host when you instantiate the
connector. As you can see, you don't need much code to get a deepstream
backend up and running. You can run the script from the command line to
start the server.

# Connect on the frontend

To connect on the frontend, the web page will need to load the deepstream
client library. You can install the client library from [bower][] or
simply obtain the [raw, minified JavaScript][clientjs]. The following
example shows how to build a simple web page that connects to the
deepstream server, creates a new record, and monitors for updates:

```html
<html>
<head>
  <script src="bower_components/deepstream.io-client-js/dist/deepstream.min.js"></script>
</head>
<body>
...
<script>
  // Connect to the deepstream server
  var ds = deepstream("localhost:6020").login();

  // Create a unique name for the new record
  var name = "myrecords/" + ds.getUid();

  // Instantiate a new record
  var record = ds.record.getRecord(name);

  // Set several properties of the new record
  record.set({
    name: "Enterprise",
    registry: "NCC-1701",
    category: "Constitution",
    crew: 430
  });

  // Subscribe to changes on the `crew` property
  record.subscribe("crew", function(value) {
    console.log("Crew count updated:", value);
  });
</script>
</body>
</html>
```

Each deepstream record has a unique ID, typically comprised of a path and
random characters. When you fetch a non-existent record by ID, the
framework will create a new record. The `set` method applies values to
record properties. When the user invokes the `set` method, the client
transmits the updated values to the server so that they can be propagated
to other clients.

The `subscribe` method allows you to track updates on a record. You can
subscribe to changes on an individual property (as demonstrated above) or
you can track changes on all of the properties of an individual record.
The client library will invoke the provided callback when it detects a
change.

In addition to records, deepstream also supports observable collections.
You can create a list of records and subscribe to see when the application
adds and removes items. I used a deepstream list in my demo application to
track the items included in the todo list.

# Build a realtime todo list

I built my deepstream todo list demo with [Vue][], a lightweight
JavaScript MVC framework. In order to make Vue's data bindings work with
deepstream records, I made a simple wrapper function that subscribes to
changes on the record and then applies those changes with Vue's `$set`
method:

```javascript
function wrapRecord(record) {
  record.subscribe(function(data) {
    for (var prop in data)
      if (data.hasOwnProperty(prop))
        record.$set(prop, data[prop]);
  });

  return record;
}
```

When I apply that function to a deepstream record in my Vue application,
it will ensure that user interface bindings instantly reflect changes that
propagate from other users. It only works one way, however.

Each item in the todo list has a checkbox and a label. The complete user
interface includes a repeating series of todo list items and an input box
that allows users to add new items:

{% raw %}
```html
<div id="todolist">
  <ul>
    <li v-repeat="items" v-on="click: toggle">
      <label>
        <input type="checkbox" checked="{{done}}">
        {{text}}
      </label>
    </li>
  </ul>

  <input type="text" v-model="newItemName" placeholder="New Item">
  <button v-on="click: newItem">Add</button>
</div>
```
{% endraw %}

The corresponding Vue controller populates the user interface with
existing items, adds a new item when the user clicks the "Add" button, and
broadcasts the update when the user toggles a checkbox in the list:

```javascript
// Connect to the deepstream server
var ds = deepstream("localhost:6020").login();

// Fetch the list of todo items
var list = ds.record.getList("todos");

function wrapRecord(record) {
  record.subscribe(function(data) {
    for (var prop in data)
      if (data.hasOwnProperty(prop))
        record.$set(prop, data[prop]);
  });

  return record;
}

var todo = new Vue({
  el: "#todolist",
  data: { items: [] },
  methods: {
    toggle: function(ev) {
      // Set the `done` property when the user toggles a checkbox
      if (ev.target.checked != undefined)
        todo.items[ev.targetVM.$index].set("done", ev.target.checked);
    },
    newItem: function() {
      // Create a name and record for the new todo item
      var name = "todos/" + ds.getUid();
      var record = ds.record.getRecord(name);

      // Use the input text as the todo list item's label
      record.set({text: this.newItemName, done: false});
      // Add the new record to the list
      list.addEntry(name);
    },
  },
  ready: function() {
    // Iterate over the items in the list...
    list.subscribe(function(data) {
      data.forEach(function(name) {
        // Fetch the associated deepstream record
        var record = ds.record.getRecord(name);
        record.whenReady(function() {
          // Wrap it and add it to the todo list
          todo.items.push(wrapRecord(record));
        });
      });
    });
  }
});
```

In the example above, the `list.subscribe` callback executes every time a
user adds new records to the list. It also executes once when the
application first starts, passing in the entire series so that I can
populate the list with existing items.

In the `toggle` event handler, I manually invoke the `set` method for the
record in order to update the `done` property with the status of the
checkbox.

The `newItem` event handler creates a new record and adds it to the list.
When I invoke the `list.addEntry` method, the application automatically
triggers the callback on the list subscription, ensuring that the new item
appears in the user interface.

# Observe updates with changefeeds

When you use the RethinkDB connector with deepstream, you can externally
access the data with conventional ReQL queries. You can even use RethinkDB
[changefeeds][] to monitor the changes in realtime. The deepstream
framework creates a separate table for each of your collections. You can
use the following query in the RethinkDB Data Explorer to see the data
from the todo list demo:

```javascript
r.db("deepstream").table("todos")
```

If you add the `changes` command to the end, you can watch for updates in
realtime. When a user adds a new item or toggles a checkbox, you will see
an update in the data explorer. Unfortunately, you can't make live changes
to deepstream records with ReQL. The framework has its own approach to
handling updates, so changes won't properly propagate to clients if you
update documents outside of the framework.

# Next steps

Deepstream made it possible for me to build a realtime todo list without
an application-specific backend code. In this case, I used the Node.js
backend script solely to configure the ports and attach the RethinkDB data
connector. Of course, there are a number of advanced features offered by
deepstream that you can use on the backend.

For example, deepstream provides backend APIs for [permissions][] and
[authentication][], which you can optionally use to implement granular
access control for record access and updates. The framework also has an
[RPC system][rpc] that you can use to invoke methods across the realtime
bridge. For more details, be sure to visit the [deepstream
documentation][dsdocs].

If you would like to try deepstream yourself, consider [installing
RethinkDB][install]. To learn more about RethinkDB, check out our
[ten-minute guide][10min].

**Resources:**

* [Complete source code of the todo list demo][source]
* [The official deepstream.io website][deepstream]
* [The deepstream.io documentation][dsdocs]

[Hoxton One]: http://www.hoxton-one.com/
[deepstream]: http://deepstream.io/
[Engine.io]: https://github.com/Automattic/engine.io
[Node.js]: https://nodejs.org/
[bower]: http://bower.io/
[npmframework]: https://www.npmjs.com/package/deepstream.io
[npmstorage]: https://www.npmjs.com/package/deepstream.io-storage-rethinkdb
[clientjs]: https://github.com/hoxton-one/deepstream.io-client-js/blob/master/dist/deepstream.min.js
[Vue]: http://vuejs.org/
[permissions]: http://deepstream.io/tutorials/permissioning.html
[authentication]: http://deepstream.io/tutorials/authentication.html
[rpc]: http://deepstream.io/tutorials/events-and-rpcs.html
[dsdocs]: http://deepstream.io/tutorials/getting-started.html
[install]: http://rethinkdb.com/docs/install/
[10min]: http://rethinkdb.com/docs/guide/python/
[changefeeds]: http://rethinkdb.com/docs/changefeeds/javascript/
[source]: https://gist.github.com/segphault/297bbe327f9e5004e1ae

