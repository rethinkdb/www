---
layout: post
title: "Introducing the official RethinkDB Java client driver"
author: Ryan Paul
author_github: segphault
---

Today, we're pleased to announce the release of our Java client driver for
RethinkDB. The client driver is a library that implements RethinkDB's ReQL
query language and provides support for connecting to a RethinkDB cluster.
With this release, we now recognize Java as an officially-supported
programming language for RethinkDB application development, alongside
Python, Ruby, and JavaScript.

The Java client driver is fully-featured. It is built on RethinkDB's
modern JSON wire protocol and supports the latest capabilities introduced
in RethinkDB 2.2. It is designed for use with Java 8 because it takes
advantage of the language's shiny new anonymous function syntax to deliver
the expressiveness that developers expect from ReQL.

<!--more-->

# Why support Java?

We chose to add Java to our lineup in order to address the growing demand
that we've seen among our users. Several third-party Java drivers have
emerged from the RethinkDB community over the years, but none are
presently complete or actively maintained. Other high-demand languages
(such as Go, for example) already have well-maintained RethinkDB drivers
produced by vibrant and active communities.

The culture of Java open source development is a little bit different--we
realized that we needed to bootstrap the development of a Java client
driver ourselves and take a more direct leadership role in order to make
it happen and keep it moving. That said, the community stepped up to
participate and provide feedback shortly after we began working on the
project in earnest. Several key features, including support for Java
object serialization, were contributed by members of the RethinkDB
community.

We also view our official Java client driver as a sort of investment in
the broader Java ecosystem. We hope that it will provide a useful starting
point for developers who want to use RethinkDB in other popular languages
for the JVM.

# Just a sip: how to use the RethinkDB Java client driver

Although we've taken steps to align the client driver with conventional
Java idioms, it exposes largely the same method-chaining API that we
provide today in other languages. This is what a simple ReQL query looks
like in Java:

```java
RethinkDB r = RethinkDB.r;
Connection<?> conn = r.connection()
                      .hostname("localhost").port(28015).connect();

// Find the odd numbers, multiply each by 2, and add the total
Long output = r.range(10)
               .filter(x -> x.mod(2).eq(1))
               .map(x -> x.mul(2)).sum().run(conn);
```

The Java client driver includes a number of convenience mechanisms
designed to help developers work around the programming language's
idiosyncrasies. For example, the driver includes special `r.array` and
`r.hashMap` methods to address Java's lack of native support or hash and
array literals. The `r.hashMap` method is often useful when assembling
JSON objects to insert into the database:

```java
r.table("fellowship").insert(r.array(
  r.hashMap("name", "Frodo").with("species", "hobbit"),
  r.hashMap("name", "Sam").with("species", "hobbit"),
  r.hashMap("name", "Merry").with("species", "hobbit"),
  r.hashMap("name", "Pippin").with("species", "hobbit"),
  r.hashMap("name", "Gandalf").with("species", "istar"),
  r.hashMap("name", "Aragorn").with("species", "human"),
  r.hashMap("name", "Boromir").with("species", "human"),
  r.hashMap("name", "Legolas").with("species", "elf"),
  r.hashMap("name", "Gimili").with("species", "dwarf")
)).run(conn);

r.table("fellowship")
 .filter(r.hashMap("species", "hobbit"))
 .update(r.hashMap("species", "halfling")).run(conn);
```

To work around Java's lack of support for named parameters, we introduced
a special `optArg` method that you can append to a query to specify the
settings for a particular query command. In the following example, we've
chained an `optArg` method after the `between` command to specify the
bound behavior:

```java
r.table("marvel")
 .between(10, 20).optArg("right_bound", "closed").run(conn);
```

Like JavaScript, Java's lack of support for operator overload requires use
to use named methods for operations like addition, subtraction,
multiplication, and equality checks. We also added a shorthand method
called `g` that you can use to retrieve the value of a specific field,
comparable in behavior to the bracket index access syntax that you'd use
in Python.

```java
r.table("fellowship")
 .filter(x -> x.g("species").eq("human")).count().run(conn)
```

RethinkDB changefeeds work out of the box, invoked with the standard
`change` command. The client driver returns a `Cursor` class with `next`
and `hasNext` methods:

```java
Cursor<HashMap> cur = r.table("fellowship").changes().run(conn);

while (cur.hasNext())
  System.out.println(cur.next());
```

When you execute a ReQL query with the Java client driver, the operation
is performed synchronously. At the present time, you will generally have
to handle threading yourself if you want to perform the queries in a
non-blocking manner.

# A behind the scenes look at how we brewed the Java driver

We designed ReQL to provide a good developer experience, with a fluent API
that feels a lot like the kind of abstractions that you get from ORMs and
query builder libraries. The downside is that it often takes a lot of
highly repetitive code to support method chaining and the wide range of
commands included in the query language. In a slightly more verbose and
explicit language like Java, that means an awful lot of boilerplate.

Josh Kuhn, the RethinkDB engineer behind the Java driver, came up with a
delightfully esoteric way to simplify the development process. He created
a Python script that parses the ReQL protocol specification and uses the
information to automatically generate much of the boilerplate--including
the code that implements the individual ReQL commands and translates
chained expressions into the equivalent wire protocol representation.

We've released the scripts and templates as open source alongside the Java
client driver itself. If you'd like to see how the automation works, you
can check out the [metajava.py][metajava] script in the RethinkDB GitHub
repository. It uses the popular Python-based
[Mako templating engine][mako] to generate the actual Java source code files. The [complete Mako templates][templates] are also available on GitHub. You can see the template output in the [gen][gen] directory,
where there's a separate Java file for each class that represents an individual ReQL command.

Now that we're unleashing Josh's arcane contraption upon the unsuspecting
world, we look forward to seeing how the RethinkDB community puts it to
use. You could, for example, write your own templates and adapt it to
generate code for a different programming language. If you are interested
in building a RethinkDB client driver, you might want to take a look and
consider if it can help. We've already seen at least one promising effort
emerge from the community: developer Brian Chavez is
[porting the Java driver to C#][dotnetport], using Razor templates
for the automatic code generation.

Of course, it's not possible to automate everything. We still had to write
several key pieces of the Java driver by hand, including the code to parse
responses and the network code that facilitates communication with a
RethinkDB cluster. The automation was, however, tremendously helpful in
achieving full ReQL coverage.

# Grinding out a demo application

To give you an idea of how the Java client driver might work in a real
world application, I built a simple chat application with a web frontend.
I built the backend with [Vert.x][vertx], a  Java framework that is
well-suited for realtime web applications.

Vert.x applications are composed of microservices, each implemented in a
class called a Verticle. The framework provides a built-in
[event bus][eventbus] that you can use to pass messages between verticles. The Vert.x event bus also has a WebSocket bridge, implemented on top of
SockJS, that you can use to propagate messages between the frontend and
the backend.

In my demo application, I have a simple HTTP POST endpoint that the
frontend client application can use to send a message. The handler for the
endpoint inserts the message into a RethinkDB table:

```java
Vertx vertx = Vertx.vertx();
Router router = Router.router(vertx);

router.route(HttpMethod.POST, "/send").handler(BodyHandler.create());
router.route(HttpMethod.POST, "/send").blockingHandler(ctx -> {
  JsonObject data = ctx.getBodyAsJson();

  if (data.getString("username") == null ||
      data.getString("text") == null) {

    ctx.response
       .setStatusCode(500)
       .putHeader("content-type", "application/json")
       .end("{\"success\": false, \"err\": \"Invalid message\"}");

    return;
  }

  Connection<?> conn = null;

  try {
    conn = r.connection().connect();

    r.db("chat").table("messages").insert(
      r.hashMap("text", data.getString("text"))
          .with("username", data.getString("username"))
          .with("time", r.now())).run(conn);

    ctx.response()
       .putHeader("content-type", "application/json")
       .end("{\"success\": true}");
  }
  catch (Exception e) {
    ctx.response()
       .setStatusCode(500)
       .putHeader("content-type", "application/json")
       .end("{\"success\": false}");
  }
  finally {
    conn.close();
  }
});

router.route().handler(StaticHandler.create().setWebRoot("public"));
vertx.createHttpServer().requestHandler(router::accept).listen(8000);
```

When implementing a Vert.x route handler, you can optionally use the
`blockingHandler` method, which tells Vert.x to use its thread pool to
execute the anonymous function in the background. This feature is useful
when performing RethinkDB queries with the Java client driver, since the
queries are executed synchronously.

Now that the POST endpoint is implemented, we need to attach a changefeed
to the table and monitor for new records. When the application detects
that there's a new message in the table, it should broadcast the message
over the Vert.x event bus:

```java
EventBus bus = vertx.eventBus();

router.route("/eventbus/*").handler(
  SockJSHandler.create(vertx).bridge(
    new BridgeOptions().addOutboundPermitted(
      new PermittedOptions().setAddress("chat"))));

new Thread(() -> {
  Connection<?> conn = null;

  try {
    conn = r.connection().connect();
    Cursor<HashMap> cur = r.db("chat").table("messages").changes()
                           .getField("new_val").without("time").run(conn);

    while (cur.hasNext())
      bus.publish("chat", new JsonObject(cur.next()));
  }
  catch (Exception e) {
    System.err.println("Error: changefeed failed");
  }
  finally {
    conn.close();
  }
}).start();
```

To set up the event bus, you have to bind it to a URL route (in this case
`/eventbus`) and then configure the permissions so that the outbound chat
messages are made accessible to frontend clients. Vert.x lets you use
arbitrary strings to define event bus addresses, which you can use to
distinguish different kinds of messages. You can configure separate
permissions for each address.

In your frontend web application, you can use the JavaScript-based Vert.x
event bus client library to handle the incoming messages and display them
to the user. In the code below, I use the `registerHandler` method to
subscribe to messages that the backend broadcasts to the "chat" address:

```javascript
var bus = new vertx.EventBus("/eventbus");

bus.onopen = function() {
  bus.registerHandler("chat", function(message) {
    console.log("Received message:", message);
  });
}
```

In my demo application, I use the lightweight Vue.js framework which lets
me take advantage of simple data binding to present messages to the user.
I can simply append new incoming messages to an array and let the
framework add them to the view. You can, however, just as easily use
alternatives like React or Angular. You can see the
[complete demo application source code](#) on GitHub.

**Resources:**

TODO

[metajava]: https://github.com/rethinkdb/rethinkdb/blob/next/drivers/java/metajava.py
[mako]: http://www.makotemplates.org/
[templates]: https://github.com/rethinkdb/rethinkdb/tree/next/drivers/java/templates
[dotnetport]: https://github.com/bchavez/RethinkDb.Driver
[gen]: https://github.com/rethinkdb/rethinkdb/tree/next/drivers/java/src/main/java/com/rethinkdb/gen/ast
[vertx]: http://vertx.io/
[eventbus]: http://vertx.io/docs/vertx-core/java/#event_bus

