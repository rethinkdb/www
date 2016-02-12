---
layout: post
title: "Build a realtime liveblog with RethinkDB and PubNub"
author: Segphault
author_github: segphault
hero_image: 2015-05-20-realtime-blog-pubnub.png
---

RethinkDB provides a persistence layer for realtime web applications, but
the rest of the stack is up to you. A number of different frameworks and
services are available to help you convey individual realtime updates to
your application's frontend.

In this blog post, I'll demonstrate to use RethinkDB with [PubNub][], a
service that provides hosting for realtime message streams. You can build
realtime web application with PubNub and RethinkDB, taking advantage of
PubNub's cloud infrastructure to simplify development and scalability. To
demonstrate how you can use PubNub with RethinkDB changefeeds, I'll show
you how to build a simple liveblog application.

<!--more-->

[PubNub]: http://www.pubnub.com/

# Why PubNub?

PubNub offers a number of advantages over implementing your realtime
streams by hand or using an open source abstraction framework like
Socket.io. Relying on PubNub's hosted infrastructure obviates a range of
scalability challenges, so you can build your application without having
to worry about how many simultaneous streams you can accommodate.

Another notable advantage of PubNub is its breadth of support for various
platforms and environments. It offers [SDKs][] for multiple programming
languages and platforms, which is particularly beneficial when you want to
build multiple frontends--spanning the web and native application
platforms.

[SDKs]: http://www.pubnub.com/developers/

PubNub also provides plugins that cover a range of common realtime usage
scenarios, reducing the amount of plumbing that you need to implement
yourself. The available plugins provide functionality like mobile push
notification support, access management control, and live analytics. In
this blog post, I'll demonstrate how you can use the access management
plugin to secure a stream--ensuring that it is only accessible to
registered users.

# Use PubNub to publish updates from a RethinkDB changefeed

RethinkDB is built for realtime applications: instead of polling for
changes, the developer can turn a query into a live feed that continuously
pushes updates to the application in realtime. In RethinkDB's ReQL query
language, the `changes` command turns an ordinary query into a realtime
changefeed. As you will see, it's easy to attach a RethinkDB changefeed to
a PubNub data stream.

PubNub uses a straightforward publish/subscribe architecture. When an
application publishes messages into a PubNub "channel", the messages are
received by subscribed clients. It's worth noting that PubNub channel
communication is fully symmetrical--your frontend and your backend are
both clients that are capable of subscribing and publishing.

When you register your application on PubNub, it will give you a
publishing key, a subscription key, and a secret key. A client needs the
subscription key in order to read messages and the publishing key in order
to post messages. The secret key is used for access management, which I'll
demonstrate later.

In this post, I'm going to show you how to use PubNub's Node.js client
library, which you can install from npm. The first step is to require and
initialize the `pubnub` client module:

```javascript
var pubnub = require("pubnub");

var pn = pubnub({
  subscribe_key: "xxxxxxxxxxxxxxx",
  publish_key: "xxxxxxxxxxxxxxx",
  secret_key: "xxxxxxxxxxxxxxx"
});
```

To publish a message from PubNub, call the `publish` method and indicate
the channel that you want to use to send the message. Your message can be
a JSON object or an individual value like a string. The following example
shows how to create a changefeed on a RethinkDB table and convey all of
the updates through a PubNub channel:

```javascript
var pubnub = require("pubnub");
var r = require("rethinkdb");

var pn = pubnub({
  subscribe_key: "xxxxxxxxxxxxxxx",
  publish_key: "xxxxxxxxxxxxxxx",
  secret_key: "xxxxxxxxxxxxxxx"
});

// Connect to a local RethinkDB database
r.connect().then(function(conn) {
  // Attach a changefeed to the `updates` table
  return r.table("updates").changes()("new_val").run(conn);
})
.then(function(changes) {
  // For each change emitted by the changefeed...
  changes.each(function(err, item) {
    // Publish the change through PubNub
    pn.publish({
      channel: "updates", message: item,
      error: function(err) {
        console.log("Failed to send message:" , err);
      }
    });
  });
});
```

In the example above, the application passes an object with three
properties to the PubNub library's `publish` method:

* The `channel` property tells PubNub to publish the message on a channel called `updates`. The channel name is arbitrary, but you will need it on the other side in order to subscribe to the messages.
* The `message` property is the JSON object that we wish to send through the channel--in this case, it's the updated object from the RethinkDB table.
* The `error` property lets us define a callback function that the library executes when it cannot properly send the message.

Now that we have our backend application configured to broadcast table
updates, we need to set up the frontend and make it subscribe to receive
the messages. For the purposes of this demo, I'm going to show you how to
make a web-based frontend that runs in the browser. Keep in mind that you
could easily take advantage of PubNub's mobile SDKs to make comparable
mobile frontends.

I created a simple web page that loads the PubNub JavaScript client
library from PubNub's CDN, subscribes to the `updates` channel, and then
prints each received message to the console:

```html
<html>
<head>
  <title>RethinkDB PubNub Demo</title>
  <script src="https://cdn.pubnub.com/pubnub.min.js"></script>

  <script>
    // Connect to PubNub's service
    var pn = PUBNUB.init({subscribe_key: "xxxxxxxxxx"});

    // Subscribe to the `updates` channel
    pn.subscribe({
      channel: "updates",
      message: function(message, env, channel) {
        // Display each message from the channel in the console
        console.log("Message:", message);
      }
    });
  </script>
</head>
<body>
  ...
</body>
</html>
```

The client only includes the subscription key, not the publication key or
the secret key. Anybody can view the source of the page, which means that
they can see and access the keys. If we give up the publication key, then
somebody might use it to post malicious messages into the application. You
should only include the publication key in your client application if you
also use the access control plugin to limit publishing.

# Build a liveblog app with RethinkDB and PubNub

I used RethinkDB and PubNub to build a simple liveblog tool. The liveblog
administrator types in messages, which the tool broadcasts to liveblog
attendees. The application uses JSON Web Tokens (JWT) for authentication,
ensuring that only the admin can send messages. The backend is implemented
in JavaScript with Node.js and Express. The browser-based frontend is
built with [Vue.js][], a lightweight JavaScript MVC framework that
supports data binding.

[Vue.js]: http://vuejs.org/

The specifics of JWT authentication are beyond the scope of this article,
but you can refer to the [complete source code][code] to see how I
implemented that part of the application. User information is obviously
stored in RethinkDB, with [bcrypt][bcrypt] for password encryption.

[code]: https://github.com/rethinkdb/rethinkdb-pubnub-liveblog
[bcrypt]: https://www.npmjs.com/package/bcrypt

When the PubNub client library receives a new message on the frontend, it
appends it to an array. I use simple data binding to display the contents
of the array to the end user:

**Frontend markup:**

{% raw %}
```html
<ul id="messages">
  <li class="message" v-repeat="messages">
    <span class="sender">{{sender}}</span>
    <span class="time">{{time | moment '(h:mm A)' }}</span>
    <p class="text">{{text}}</p>
  </li>
</ul>
```
{% endraw %}

**Frontend JavaScript:**

```javascript
Vue.filter("moment", function(value, fmt) {
  return moment(value).format(fmt).replace(/'/g, "");
});

var app = new Vue({
  el: "body",
  data: {
    messages: [],
  },
  ready: function() {
    var pn = PUBNUB.init({subscribe_key: "xxxxxxxxxxxxxxx"});

    var that = this;
    pn.subscribe({
      channel: "updates",
      message: function(message, env, channel) {
        that.messages.unshift(message);
      }
    });
  }
});
```

Of course, that will only display new messages that are sent to the stream
while the user is viewing the page. I also had to add a way for the user
to retrieve the existing messages so that they can see what they missed.
On the backend, I added an `/api/history` URL endpoint that provides a
JSON record of current liveblog messages, ordered by timestamp:

```javascript
app.get("/api/history", function(req, res) {
  r.connect(config.database).then(function(conn) {
    return r.table("updates").orderBy(r.desc("time")).run(conn)
      .finally(function() { conn.close(); });
  })
  .then(function(stream) { return stream.toArray(); })
  .then(function(output) { res.json(output); });
});
```

On the frontend, the application simply has to perform an XHR request to
that endpoint and put the returned JSON objects into the messages array.

To handle message publication, I added a textbox that is only visible to
the administrator. When the user types a message into the box and hits
enter, the frontend send an HTTP POST request to an `/api/send` URL
endpoint that I implemented on the backend. 

**Frontend markup:**

```html
<div id="messagebox" v-if="user.admin">
    <textarea v-model="message" v-on="keyup:send | key enter" placeholder="Type your message here"></textarea>
</div>
```

**Frontend JavaScript:**

```javascript
var app = new Vue({
  ...
  methods: {
    send: function(ev) {
      fetch("/api/send", {
        method: "post",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token
        },
        body: JSON.stringify({message: this.message})
      })
      .then(function(output) { return output.json(); })
      .then(function(response) { app.message = null; });
    },
    ...
  }
});
```

You can send that POST request to the `/api/send` URL endpoint however you
want, but you'll notice that I chose to use the [W3C Fetch method][fetch].
I like using Fetch because its Promise-based output is easy to consume.
Fetch isn't supported in very many browsers yet, however, so I
[use a polyfill][polyfill] to get it today.

[fetch]: https://fetch.spec.whatwg.org/
[polyfill]: https://cdn.polyfill.io/

My backend code checks to make sure that the user who sent the message is
an admin and then adds the message to the database. We already have a
changefeed on the `updates` table wired up to the PubNub channel, so we
know that the application will broadcast it to the frontend.

```javascript
app.post("/api/send", function(req, res) {
  if (!req.user.admin)
    return res.status(401).json({success: false, error: "Unauthorized User"});

  r.connect().then(function(conn) {
    return r.table("updates").insert({
      text: req.body.message,
      sender: req.user.username,
      time: r.now()
    }).run(conn).finally(function() { conn.close(); });
  })
  .then(function() { res.json({success: true}); });
});
```

That's pretty much all you need to build a simple liveblog application
with RethinkDB and PubNub.

# Use PubNub access management to control stream availability

I added a few more features to my application in order to explore PubNub's
more advanced capabilities. I used PubNub's access management plugin to
put a registration wall in front of the liveblog, making it so that only
users with accounts are able to see the content.

It's easy to add an authentication check to the `/api/history` method that
I use to provide message backlog. But I needed PubNub's access control
system in order to protect the stream itself, preventing unauthorized
users from accessing the latest updates.

When the application starts, I have it universally disable reading so that
users can't access the streams without authenticating:

```javascript
var pn = pubnub({ ... });

pn.grant({
  write: true, read: false,
  callback: function(c) { console.log("Permission set:", c); }
});
```

In the backend authentication handling code, which executes when the user
logs in, I use the PubNub library's `grant` method to enable stream
reading for the individual user's JWT access token:

```javascript
pn.grant({
  channel: "updates", auth_key: acct.token,
  read: true, write: false
  callback: function(c) { console.log("Set permissions:", c); }
});
```

On the client side, when the user completes the login process, I give
their newly-received access token to the PubNub client library:

```javascript
var app = new Vue({
  ...
  login: function(ev) {
      fetch("/api/user/login", {
        method: "post",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: this.username,
          password: this.password
        })
      })
      .then(function(output) { return output.json(); })
      .then(function(response) {
        var pn = PUBNUB.init({
          subscribe_key: "xxxxxxxxxxxxxxx",
          auth_key: response.token
        });
        ...
```

Now users will only be able to access the message stream if they
authenticate and provide an access token that has appropriate permissions.
If you wanted, you could eliminate the `/api/send` method entirely: simply
make the frontend publish the administrator's messages into a channel
while relying on access control to prevent unauthorized users from sending
anything. I'm going to leave that as an exercise for the reader.

Although there are good libraries like [Socket.io][] available for
developers who want self-hosted realtime message delivery, PubNub offers a
compelling option for developers who want to offload their realtime
streams to the cloud. PubNub's advanced options and useful plugins can
also help accelerate development.

[Socket.io]: http://socket.io

Now that you have seen what you can build with RethinkDB and PubNub,
[install RethinkDB][install] and check out our ten-minute [quickstart
guide][qs].

[install]: http://rethinkdb.com/docs/install/
[qs]: http://rethinkdb.com/docs/guide/javascript/

**Resources:**

* [PubNub developer center](http://www.pubnub.com/developers/)
* [PubNub's access management plugin docs](http://www.pubnub.com/developers/tutorials/access-manager/) 
* [Full source code][code] for the liveblog demo
