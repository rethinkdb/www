---
layout: post
title: "Advancing the realtime web"
author: Slarva Akhmechet
author_github: coffeemug
---

Over the past few months the team at RethinkDB has been working on a project to
make building modern, realtime apps dramatically easier. The upcoming features
are the start of an exciting new database access model -- instead of polling
the database for changes, the developer can tell RethinkDB to continuously push
updated query results to applications in realtime.

This work started as an innocuous feature to help developers integrate
RethinkDB with other realtime systems. A [few releases ago][1] we shipped
[changefeeds][] -- a way to subscribe to change notifications in the database.
Whenever a document changes in a table, the server pushes a notification
describing the change to subscribed clients.  You can subscribe to changes on a
table like this:

[1]: {% post_url 2014-06-12-1.13-release %}
[changefeeds]: /docs/changefeeds

```py
r.table('accounts').changes().run(conn)
```

Originally we intended this feature to help developers push data from RethinkDB
to specialized data stores like ElasticSearch and message systems like
RabbitMQ, but the release generated enormous excitement we didn't expect.
Digging deeper, we saw that many web developers used changefeeds as a solution
to a much broader problem -- how do you adapt the database to push realtime
data to applications?
<!--more-->

This turned out to be an important problem for so many developers that we
expanded RethinkDB's architecture to explicitly support realtime apps. The
first batch of the new features will ship in a few days in the upcoming 1.16
release of RethinkDB, and I'm very excited to share what we've been working on
in this post.

# Why is building realtime apps so hard?

The query-response database access model works well on the web because it maps
directly to HTTP's request-response. However, modern marketplaces, streaming
analytics apps, multiplayer games, and collaborative web and mobile apps
require sending data directly to the client in realtime. For example, when a
user changes the position of a button in a collaborative design app, the server
has to notify other users that are simultaneously working on the same project.
Web browsers support these use cases via WebSockets and long-lived HTTP
connections, but adapting database systems to realtime needs still presents a
huge engineering challenge.

A naive way to support live updates is to periodically poll the database for
changes, but this solution is unworkable because it entails a tradeoff between
the number of concurrent users and the polling interval. Even a small number of
users polling the database will place a tremendous load on the database
servers, requiring the administrator to increase the polling interval. In turn,
high polling intervals very quickly result in an untenable user experience.

A scalable solution to this problem involves many cumbersome steps:

- Hooking into replication logs of the database servers, or writing custom data
  invalidating logic for realtime UI components.
- Adding messaging infrastructure (e.g. RabbitMQ) to your project.
- Writing sophisticated routing logic to avoid broadcasting every message to
  every web server.
- Reimplementing database functionality in the backend if your app requires
  realtime computation (e.g. realtime leaderboards).

All this requires enormous commitment of time and engineering resources. This
[tech presentation][] from Quora gives a good overview of how challenging it
can be. The upcoming 1.16 release of RethinkDB is our take on helping
developers build realtime apps with minimal effort, and includes the first
batch of realtime push features to tackle this problem.

[tech presentation]: http://www.quora.com/Shreyes-Seshasai/Posts/Tech-Talk-webnode2-and-LiveNode

# The database for the realtime web

A major design goal was to make the implementation non-invasive and simple to
use. RethinkDB users can get started with the database by using a familiar
request-response query paradigm. For example, if you're generating a web page
for a visual web design app, you can load the UI elements of a particular
project like this:

```py
> r.table('ui_elements').get_all(PROJECT_ID, index='projects').run(conn)
{ 'id': UI_ELEMENT_ID,
  'project_id': PROJECT_ID
  'type': 'button',
  'position': [100, 100],
  'size': [200, 100] }
```

But what if your design app is collaborative, and you want to show updates to
all designers of a project in realtime? The 1.16 release of RethinkDB
significantly expands the `changes` command to work on a much larger set of
queries. The `changes` command lets you get the result of the query, but also
asks the database to continue pushing updates to the web server as they happen
in realtime, without the developer doing any additional work:

```py
> r.table('ui_elements').get_all(PROJECT_ID, index='projects').changes().run(conn)
{ 'new_val':
  { 'id': UI_ELEMENT_ID,
    'project_id': PROJECT_ID
    'type': 'button',
    'position': [100, 100],
    'size': [200, 100] }
}
```

The first result of the query is just the value of the document. However, when
the developer tacks on the `changes` command, RethinkDB will keep the cursor
open, and push updates onto the cursor any time a relevant change occurs in the
database. For example, if a different user moves the button in a project, the
database will push a diff to every connected web server interested in the
particular project, informing them of the change:

```py
{ 'old_val':
  { 'id': UI_ELEMENT_ID,
    'project_id': PROJECT_ID
    'type': 'button',
    'position': [100, 100],
    'size': [200, 100] },
  'new_val':
  { 'id': UI_ELEMENT_ID,
    'project_id': PROJECT_ID
    'type': 'button',
    'position': [200, 200],  # the position has changed
    'size': [200, 100] }
}
```

Any time a web or a mobile client connects to your Python, Ruby, or Node.js
application, you can create a realtime feed using the official RethinkDB
[drivers][]. The database will continuously push query result updates to your
web server, which can forward the changes back to the client in realtime using
WebSockets or one of the many wrapper libraries like [SockJS][], [socket.io](),
or [SignalR][].  Additionally, you'll be able to access the functionality from
most languages using one of the many community supported [drivers][].

[drivers]: /docs/install-drivers/
[SockJS]: https://github.com/sockjs/sockjs-client
[socket.io]: http://socket.io/
[SignalR]: http://signalr.net/

The push access model eliminates the need for invalidation logic in the UI
components, additional messaging infrastructure, complex routing logic on your
servers, and custom code to reimplement aggregation and sorting in the
application. The `changes` command works on a large subset of queries and is
tightly integrated into RethinkDB's architecture. For example, if you wanted to
create an animated line graph of operation statistics for all tables in your
production database, you could set up a feed on the internal statistics table
to monitor the RethinkDB cluster itself:

```py
> r.db('rethinkdb').table('stats').filter({ 'db': 'prod' }).changes().run(conn)
```

The architecture is designed to be scalable. We're still running benchmarks,
but you should be able to create thousands of concurrent changefeeds to scale
your realtime apps, and the results will be pushed within milliseconds.

We've also built in many bells and whistles like latency awareness, that make
building realtime apps much more convenient. For example, if the query results
change too quickly and you don't want to update the DOM more frequently than
fifty milliseconds, you can tell `changes` to squash updates on a fifty
millisecond window, and the database will take care of aggregating diffs and
removing duplicates:

```py
> r.table('ui_elements').get_all(PROJECT_ID, index='projects').changes(squash=0.05).run(conn)
```

# Comparison with realtime sync services

There are many existing realtime sync services that significantly ease the pain
of building realtime applications. [Firebase][], [PubNub][], and [Pusher][] are
notable examples, and there are many others. These services are excellent for
getting up and running quickly. They let you sync documents across multiple
browsers, offer sophisticated security models, and integrate with many existing
web frameworks.

[Firebase]: https://www.firebase.com/
[PubNub]: http://www.pubnub.com/
[Pusher]: https://pusher.com/

The upcoming features in RethinkDB are fundamentally different from realtime
sync services in four critical ways.

Firstly, most existing realtime sync services offer very limited querying
capabilities. You can query for a specific document and perhaps a range of
documents, but you can't express even simple queries that involve any
computation. For example, sorting, advanced filtering, aggregation, joins, or
subqueries are either limited or not available at all. This limitation turns
out to be critical for real world applications, so most users end up using
realtime sync services side by side with traditional database systems, and
build up complex code to duplicate data between the two.

In contrast, RethinkDB is a general purpose database that allows you to easily
express queries of arbitrary complexity. This eliminates the need for multiple
pieces of infrastructure and additional code to duplicate data and keep it in
sync across multiple services.

Secondly, the push functionality of realtime sync services is limited to single
documents. You can sync documents across clients, but you can't get a realtime
incremental feed for more complex operations. In contrast, RethinkDB allows you
to get a feed on queries, not just documents. For example, suppose you wanted
to build a realtime leaderboard of top five gameplays in your game world. This
requires sorting the gameplays by score in descending order, limiting the
resultset to five top gameplays, and getting a continuous incremental feed that
pushes updates to your clients any time the resultset changes. This
functionality isn't available in realtime sync services, but is trivial in
RethinkDB:

```py
r.table('gameplays').order_by(index=r.desc('score')).limit(5).changes().run(conn)
```

Any time the database gets updated with a new gameplay, this query will inform
the developer which items dropped off the leaderboard, and which new gameplays
should be included. Internally, the database doesn't merely rerun the query any
time there is a change to the `gameplays` table -- the changefeeds are
recomputed incrementally and efficiently.

Thirdly, realtime sync services are closed ecosystems that run in the cloud.
While a hosted version of RethinkDB is available through our partners at
[Compose.io][], both the [protocol][] and the [implementation][] are, and
always will be, open-source.

[Compose.io]: https://www.compose.io/rethinkdb
[protocol]: https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/ql2.proto
[implementation]: https://github.com/rethinkdb/rethinkdb

Finally, most existing realtime sync services are built to allow access to
their API directly from the web browser. This eliminates the need for building
a backend in simple applications, and lets new users quickly deploy their apps
with less hassle. As a general purpose database RethinkDB expects to be
accessed from a backend server, and does not yet provide a sufficiently robust
security model to be accessed directly from the web browser. We're playing with
the idea of building a secure proxy server to let web clients access RethinkDB
directly from the browser, so eventually you might not need to write backend
code if your application is simple enough. However, unlike realtime sync
services, for now you have to access RethinkDB feeds through the backend code
running in your web server.

# Comparison with hooking into the replication log

Most traditional database systems offer access to their replication log, which
allows clients to learn about the updates happening in the database in
realtime. Many infrastructures for realtime apps are built on top of this
functionality. There are three fundamental differences between RethinkDB's
changefeeds and hooking into the replication log of a database.

Firstly, like with realtime sync, hooking into the replication log gives you
access to updates on individual documents. In contrast, RethinkDB's changefeeds
allow you to get feeds on query resultsets. Consider the example above, where
we're building a leaderboard of top five gameplays in a game world:

```py
r.table('gameplays').order_by(index=r.desc('score')).limit(5).changes().run(conn)
```

To rebuild this functionality on top of a replication log your application
would need to keep track of top five gameplays, and you'd have to write custom
code to compare each new record in the `gameplays` table to decide if it
replaces any of the gameplays in the leaderboard. More importantly, consider
what happens if the game admin decides the player cheated and their gameplay
score has to be reduced. Your code would have to go back to the database and
recompute the query from scratch, because it has no information about which
gameplay has the new record that should be on the leaderboard.

Writing this code is doable, but is fairly complex and error-prone. In a large
application, the complexity can add up quickly if you have many realtime
elements. In contrast, RethinkDB's query engine eliminates this complexity by
automatically taking care of the computation and sending you the correct
updates as the resultset changes in realtime.

Secondly, as you move to sharded environments, working with a replication log
presents additional complexity as there isn't a single replication log to deal
with. Your application would need to subscribe to multiple replication logs,
and manually aggregate the events from replication logs for each shard. In
contrast, RethinkDB automatically takes care of handling shards in the cluster,
and changefeeds present unified views to your application.

Finally, most database systems don't offer granular filtering functionality for
replication logs, so your clients can't get only the parts of the log they're
interested in. This presents non-trivial scalability challenges because your
infrastructure has to deal with the firehose of all database events, and you
need to write custom code to route only the relevant events to appropriate web
servers. In contrast, RethinkDB handles scalability issues in the cluster, and
each feed gives you exactly the information you need for a particular client.

RethinkDB's changefeeds operate on a higher level of abstraction than
traditional replication logs, which significantly reduces the amount of custom
code and operational challenges the application developer has to consider.

# Integrating with realtime web frameworks

One of the more notable projects that helps developers build realtime apps is
[Meteor][]. Meteor is an open-source platform for building realtime apps in
JavaScript that promises a significantly improved developer experience. It
handles a lot of the boilerplate necessary to build responsive interfaces with
live updates, provides a complete platform with client-side and server-side
components, and offers many advanced features like latency compensation and
security out of the box. The team is making great strides in scalability and
maturity of the platform, and many companies are starting to use Meteor to
build the next generation of web applications.

[Meteor]: http://meteor.com

Meteor is part of the Node.js ecosystem, and multiple other projects have
popped up to bring its functionality to other languages.  [Volt][] is a
framework that implements similar functionality in Ruby, and [webalchemy][] is
an alternative platform for Python. These projects are less mature, but have
picked up a lot of interest in their respective ecosystems, and are likely to
gain a lot of momentum once they accumulate enough functionality to let
developers build high quality, scalable apps.

[Volt]: http://voltframework.com/
[webalchemy]: http://skariel.org/webalchemy/

Meteor, Volt, and webalchemy frameworks run on top of databases, so they're
ultimately constrained by the realtime functionality and scalability of
existing database systems. We've been collaborating with the Meteor team to
ensure our design will work well with these and other similar projects. A few
community members have been working on a RethinkDB integration with Meteor and
Volt, and we expect robust integrations to become available in the coming
months.

# More work ahead

The upcoming 1.16 release contains only a subset of the functionality we'd like
to include. In the next few releases we plan to expand realtime push even
further:

- We're discussing the implementation for restartable feeds [here][#3471] and
  [here][#3579]. Feedback welcome!
- We'd like to make more complex queries available via realtime push. In
  particular, efficient realtime push implementations for the `eq_join` command
  and map/reduce are fairly complex, and aren't making it into 1.16.
- Exposing the database to the internet entails serious security concerns, so
  we're kicking around ideas for a secure proxy to enable direct browser access
  of realtime feeds.

[#3471]: https://github.com/rethinkdb/rethinkdb/issues/3471
[#3579]: https://github.com/rethinkdb/rethinkdb/issues/3579


This work is guided by three high level design principles:

- We believe it's important for realtime database infrastructure to be
  __open__. Both the [protocol][] and the [implementation][] are, and always
  will be, open-source.
- The implementation should be __non-invasive__ and very __simple__ to use.
  Developers shouldn't have to care about realtime features until they're ready
  to add the functionality to their apps.
- Realtime functionality should be __efficient, scalable, and tightly
  integrated__ with the rest of the database. It shouldn't feel like an
  afterthought.

[protocol]: https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/ql2.proto
[implementation]: https://github.com/rethinkdb/rethinkdb

# Advancing the realtime web

The new functionality is a start of an exciting new database access model that
eliminates many complex steps necessary for building realtime apps today. There
is no need to poll the database for changes or introduce additional
infrastructure like RabbitMQ. RethinkDB pushes relevant changes to the web
server the instant they occur. The amount of additional code the developer has
to write to implement realtime functionality in their apps is minimal, and all
scalability issues are handled by the RethinkDB cluster.

We'll be releasing the realtime extensions to RethinkDB in the next few days
along with tutorials and documentation. In the meantime, you can watch the
video with a live demo of the features:

<iframe style="margin: 20px 0;" width="560" height="315" src="//www.youtube.com/embed/GuDP6hyxcng" frameborder="0" allowfullscreen></iframe>

We're hoping RethinkDB 1.16 will make building realtime apps dramatically
simpler and more accessible. Stay tuned for more updates, and please share your
feedback with the [RethinkDB team][contact]!

[contact]: http://www.rethinkdb.com/community

