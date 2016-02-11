---
layout: post
title: "Using RethinkDB with io.js: exploring ES6 generators and the future of JavaScript"
author: Ryan Paul
author_github: segphault
---

A group of prominent Node.js contributors recently launched a community-driven
fork called [io.js][]. One of the most promising advantages of the new fork is
that it incorporates a much more recent version of the V8 JavaScript runtime.
It happens to support a range of useful [ECMAScript 6][1] (ES6) features right
out of the box.

[io.js]: https://iojs.org/
[1]: http://git.io/es6features

Although io.js is still too new for production deployment, I couldn't resist
taking it for a test drive. I used io.js and the experimental [rethinkdbdash][]
driver to get an early glimpse at the future of ES6-enabled RethinkDB
application development.
<!--more-->

[rethinkdbdash]: https://github.com/neumino/rethinkdbdash

# ES6 in Node.js and io.js

ES6, codenamed Harmony, is a new version of the specification on which the
JavaScript language is based. It defines new syntax and other improvements that
greatly modernize the language. The infusion of new hotness makes the
development experience a lot more pleasant.

Node.js has a special command-line flag that allows users to enable
experimental support for ES6 features, but the latest stable version of Node
doesn't give you very much due to its reliance on a highly outdated version of
V8. The unstable Node 0.11.x pre-release builds provide more and better ES6
support, but still hidden behind the command-line flag.

In io.js, the ES6 features that are stable and maturely-implemented in V8 are
[flipped on by default][2]. Additional ES6 features
that are the subject of ongoing development are still available through
command-line flags. The io.js approach is relatively granular, but strongly
encourages adoption of features that are considered safe to use.

[2]: https://iojs.org/es6.html

Among the most exciting ES6 features available in both Node 0.11.x and io.js is
support for [generators][3].  A generator function, which is signified by
putting an asterisk in front of the name, outputs an [iterator][4] instead of a
conventional return value. Inside of a generator function, the developer uses
the [`yield`][5] keyword to express the values that the iterator emits.

[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*
[4]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/The_Iterator_protocol
[5]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/yield

It's a relatively straightforward feature, but some novel uses open up a few
very interesting doors. Most notably, developers can use generators to
[simplify asynchronous programming][6].  When an asynchronous task is expressed
with a generator, you can make it so that the `yield` keyword will suspend
execution of the current method and resume when the desired operation is
complete. Much like the C# programming language's [`await`][7] keyword, it
flattens out asynchronous code and allows it to be written in a more
conventional, synchronous style.

[6]: http://davidwalsh.name/async-generators
[7]: http://msdn.microsoft.com/en-us/library/hh191443.aspx

# Introducing rethinkdbdash

Developed by RethinkDB contributor [Michel Tu][], rethinkdbdash is an
experimental RethinkDB driver for Node.js that provides a connection pool and
several other advanced features. When used in an environment that supports
generators, rethinkdbdash optionally lets you handle asynchronous query
responses with the `yield` keyword as an alternative to callbacks or promises.

[Michel Tu]: https://github.com/neumino

The following example uses rethinkdbdash with generators to perform a sequence
of asynchronous operations. It will create a database, table, and index, which
it will then populate with remote data:

```javascript
var bluebird = require("bluebird");
var r = require("rethinkdbdash")();

var feedUrl = "earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.geojson";

bluebird.coroutine(function *() {
  try {
    yield r.dbCreate("quake").run();
    yield r.db("quake").tableCreate("quakes").run();
    yield r.db("quake").table("quakes")
                       .indexCreate("geometry", {geo: true}).run();

    yield r.db("quake").table("quakes")
                       .insert(r.http(feedUrl)("features")).run();
  }
  catch (err) {
    if (err.message.indexOf("already exists") == -1)
      console.log(err.message);
  }
})();
```

Each time that the path of execution hits the `yield` keyword, it jumps out and
waits for the operation to finish before continuing. The behavior is similar to
what you would get if you used a promise chain, separating each operation into
a `then` method call. The following is the equivalent code, as you would write
it today using promises and the official RethinkDB JavaScript driver:

```javascript
var conn;
r.connect().then(function(c) {
  conn = c;
  return r.dbCreate("quake").run(conn);
})
.then(function() {
  return r.db("quake").tableCreate("quakes").run(conn);
})
.then(function() {
  return r.db("quake").table("quakes").indexCreate(
    "geometry", {geo: true}).run(conn);
})
.then(function() { 
  return r.db("quake").table("quakes")
                      .insert(r.http(feedUrl)("features")).run(conn); 
})
.error(function(err) {
  if (err.msg.indexOf("already exists") == -1)
    console.log(err);
})
.finally(function() {
  if (conn)
    conn.close();
});
```

The built-in connection pooling in rethinkdbdash carves off a few lines by
itself, but even after you factor that in, the version that uses the `yield`
keyword is obviously a lot more intuitive and concise. The generator approach
also happens to be a lot more conducive to using traditional exception-based
error handling.

# Use rethinkdbdash in a web application

To build a working application, I used rethinkdbdash with [Koa][], a
next-generation Node.js web framework designed by the team behind Express. Koa
is very similar to Express, but it makes extensive use of generators to provide
a cleaner way of integrating middleware components.

[Koa]: http://koajs.com/

The following example defines a route served by the application that returns
the value of a simple RethinkDB query. It fetches and orders records, emitting
the raw JSON value:

```javascript
var app = require("koa")();
var route = require("koa-route");
var r = require("rethinkdbdash")();

app.use(route.get("/quakes", function *() {
  try {
    this.body = yield r.db("quake").table("quakes").orderBy(
      r.desc(r.row("properties")("mag"))).run();
  }
  catch (err) {
    this.status = 500;
    this.body = {success: false, err: err};
  }
}));
```

When the asynchronous RethinkDB query operation completes, its output becomes
the return value of the `yield` expression. The route handler function takes
the returned JSON value and assigns it to a property that represents the
response body for the HTTP GET request. It doesn't get much more elegant than
that.

# A promising future awaits

Generators offer a compelling approach to asynchronous programming. In order to
make the pattern easier to express and use with promises, developers have
already proposed adding an [official `await` keyword][8] to future versions of
the language.

[8]: https://github.com/lukehoban/ecmascript-asyncawait

By bringing the latest stable V8 feature to the masses, the io.js project holds
the potential to bring us the future just a little bit faster. Although the
developers characterize it as "beta" quality in its current form, it's worth
checking out today if you want to get a tantalizing glimpse of what's coming
`.next()`.

Give RethinkDB a try with io.js or Node. You can follow our [thirty-second
RethinkDB quickstart guide][guide]. 

[guide]: /docs/quickstart

# Resources

* The official io.js [website][9] and [GitHub repo][10]
* Michel Tu's [rethinkdbdash library][11]
* The official [Koa website][12]
* A [sample RethinkDB application][13] built with rethinkdbdash and Koa

[9]: https://iojs.org/
[10]: https://github.com/iojs/io.js
[11]: https://github.com/neumino/rethinkdbdash
[12]: http://koajs.com/
[13]: https://github.com/neumino/rethinkdbdash-examples

