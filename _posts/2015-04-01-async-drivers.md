---
layout: post
title: "RethinkDB 2.0 drivers: native support for Tornado and EventMachine"
author: Ryan Paul
author_github: segphault
---

Asynchronous web frameworks like [Tornado][] and [EventMachine][] simplify
realtime application development in Python and Ruby. They support an
event-driven programming model that fits the realtime web, making it easy to
use WebSocket connections without blocking. You can plug in RethinkDB
changefeeds&mdash;which allow you to subscribe to changes on database
queries&mdash;to extend that event-driven model to your persistence layer,
offering a full backend stack for pushing live updates to your frontend.

[Tornado]: http://www.tornadoweb.org/en/stable/
[EventMachine]: https://github.com/eventmachine/eventmachine

The upcoming RethinkDB 2.0 release introduces support for using Tornado and
EventMachine to perform asynchronous queries in the Python and Ruby client
drivers. When we [announced the availability][1] of the RethinkDB 2.0 release
candidate last week, the updated client drivers weren't quite ready yet. Today,
we're issuing fresh RethinkDB 2.0 RC client drivers that fully incorporate the
new functionality ([download them here][2]).
<!--more-->

[1]: {% post_url 2015-01-30-1.16-release %}
[2]: https://github.com/rethinkdb/rethinkdb/releases/tag/v2.0.0-0RC1

Asynchronous query execution is particularly useful in applications that
consume [changefeeds][]. You can use asynchronous queries to keep multiple
changefeeds running in the background, operating continuously without blocking
execution.

[changefeeds]: /docs/changefeeds

In this blog post, I'll demonstrate basic RethinkDB usage with Tornado and
EventMachine and I'll show you how I used the EventMachine integration in Ruby
to build a realtime application with RethinkDB and [Faye][].

[Faye]: http://faye.jcoglan.com/

# Asynchronous queries in Python

Tornado is a web framework and collection of asynchronous networking libraries
for Python. In RethinkDB's new Python client driver, you can use Tornado
coroutines to perform queries in the background:

```python
import rethinkdb as r
from tornado import ioloop, gen

r.set_loop_type("tornado")

@gen.coroutine
def print_changes():
    conn = yield r.connect(host="localhost", port=28015)
    feed = yield r.table("table").changes().run(conn)
    while (yield feed.fetch_next())
        change = yield feed.next()
        print(change)

ioloop.IOLoop.current().add_callback(print_changes)
```

The example demonstrates how to create a changefeed that tracks updates on a
given table. It uses a Tornado coroutine that runs in the background to print
each update that occurs on the table.

The `r.set_loop_type` method tells the client driver to integrate with the
Tornado event loop. In the future, users will be able to specify other
asynchronous programming frameworks to use instead.

You can apply the `gen.coroutine` decorator to turn a function into a Tornado
coroutine. When you run a coroutine, the `yield` keyword causes execution of
the function to suspend temporarily until the operation after the yield keyword
is complete. Tornado coroutines let you express asynchronous operations in a
relatively flat, synchronous style.

The `print_changes` function iterates over a cursor returned by a changefeed,
using the `yield` keyword to pause execution until the next item is available
from the changefeed. The `ioloop.IOLoop` line tells Tornado to run the
coroutine in the background. For more details, you can refer to our preliminary
[Tornado integration docs][3].

[3]: https://github.com/rethinkdb/docs/blob/issue-684-async-docs/2-query-language/asynchronous.md#python-and-tornado

# Asynchronous queries in Ruby

EventMachine is an event-driven concurrency library for Ruby. In RethinkDB's
new Ruby client driver, you can use EventMachine to perform queries in the
background:

```ruby
require "rethinkdb"
include RethinkDB::Shortcuts

conn = r.connect host: "localhost", port: 28015

EM.run do
  r.table("table").changes.em_run(conn) do |err, change|
    puts change 
  end
end
```

The example above demonstrates how to create a changefeed that tracks updates
on a particular table. It uses EventMachine to run in the background and print
each update that occurs on the table.

To perform queries with EventMachine, use `em_run` instead of the conventional
`run` method. When you call `em_run`, you can use a Ruby block to handle the
output. For a command with a single value output, the block will execute once.
When you consume a changefeed or perform a command that returns a cursor, the
block will execute once for each item.  Always remember to wrap an `EM.run`
block around code that uses EventMachine. For more details about how to use
EventMachine in the Ruby client driver, you can refer to our preliminary
[EventMachine integration docs][4].

[4]: https://github.com/rethinkdb/docs/blob/issue-684-async-docs/2-query-language/asynchronous.md#ruby-and-eventmachine


# Build a realtime Ruby app with Faye and RethinkDB

To take the asynchronous query support for a test drive, I built a simple
realtime Ruby app with [Faye][] and RethinkDB. Faye is an open source
publish/subscribe framework that includes a backend server component and a
frontend JavaScript library that runs in the web browser.

Faye makes it easy to do realtime messaging between client and server. It uses
WebSockets where available, but can also fall back on long polling.  My simple
demo app is a realtime todo list. When any user adds a new item to the list or
checks off an existing item, the updates propagate to every user. The
application stores the global todo list in RethinkDB. A changefeed on the
`todo` table uses Faye to send updates to all of the users.

The following code is responsible for initializing Faye, attaching a changefeed
to the `todo` table, and broadcasting all updates to realtime clients:

```ruby
EM.run do
  ...
  
  # Initialize Faye and bind its URLs to the path /faye
  App = Faye::RackAdapter.new Sinatra::Application, mount: "/faye"

  # Establish a connection to the database
  conn = r.connect host: "localhost", port: 28015
  
  # Attach a changefeed to the "todo" table
  r.table("todo").changes.em_run(conn) do |err, change|
     # Publish each change to the "/todo/update" channel
     App.get_client.publish("/todo/update", change)
  end

  ...
end

```

Faye applications define path-delimited channels where messages are sent and
received. When an application publishes a message to a channel, all subscribers
receive the published data. In the example above, the application publishes
changefeed updates to the `/todo/update` channel. The frontend client
subscribes to that channel in order to receive the updates:

```javascript
faye.subscribe("/todo/update", function(data) {
  console.log(data);
});
```

Both the client and the server are capable of publishing messages. The server
can subscribe to a channel in order to receive instructions from the frontend.
For example, when a user adds a todo list item, the frontend JavaScript client
publishes a message to a Faye channel:

```javascript
todo.add = function() {
  faye.publish("/todo/add", todo.newItem);
};
```

The server subscribes to that channel in order to receive and handle the update:

```ruby
App.get_client.subscribe "/todo/add" do |m|
  if m.is_a? String
    r.table("todo").insert(text: m, done: false).run(Conn)
  end
end
```

In theory, I could have the frontend client subscribe to the `/todo/add`
channel in order to see new items added by other users. But I want to relay all
operations through the server so that I can update the backend data store and
perform proper validation.

In addition to realtime communication with Faye, the application also includes
an embedded Sinatra server. It uses Sinatra to expose a REST endpoint with a
JSON representation of the todo list. The frontend, which is built with
Polymer, uses the JSON API to populate its initial state.

The following code demonstrates how to embed Sinatra in a Faye application. It
includes the `/todo` URL endpoint, which returns the JSON todo list data:

```ruby
EM.run do
  Conn = r.connect host: "localhost", port: 28015

  class SinatraApp < Sinatra::Base
    get "/" do
      redirect "/index.html"
    end

    get "/todo" do
      r.table("todo").coerce_to("array").run(Conn).to_json
    end
  end

  App = Faye::RackAdapter.new SinatraApp, mount: "/faye"

  ...
  
  Rack::Server.start app: App, Port: 4000
end
```

It's worth noting that the individual URL endpoints handled by Sinatra can also
get in on the realtime action. You can call `App.get_client.publish` in any of
the URL route handlers if you want to make them pass realtime data to the
frontend.

Asynchronous programming frameworks take a lot of the complexity out of
realtime application development. Used with RethinkDB changefeeds and WebSocket
abstraction libraries, you have a fairly compelling stack for propagating live
updates and handling realtime events.

**Resources:**

* See the [complete source code][6] of the todo list application
* Download the [RethinkDB 2.0 release candidate][7]
* Read the [RethinkDB async docs][8]

[6]: https://gist.github.com/segphault/f9c8f4c769429fd8f65d
[7]: https://github.com/rethinkdb/rethinkdb/releases/tag/v2.0.0-0RC1
[8]: https://github.com/rethinkdb/docs/blob/issue-684-async-docs/2-query-language/asynchronous.md
