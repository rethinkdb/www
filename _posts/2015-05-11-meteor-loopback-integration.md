---
layout: post
title: "Use RethinkDB with LoopBack and Meteor"
author: Ryan Paul
author_github: segphault
---

Now that RethinkDB is ready for adoption in production environments, a
growing number of developers are working to integrate it with their favorite
backend frameworks. We've seen several particularly promising integrations
emerge over the past few weeks.

# Meteor integration

Meteor developer [Slarvae Kim][Slarvae] published a [video][] on YouTube that
demonstrates his proof-of-concept [bridge between Meteor and
RethinkDB][bridge]. Meteor is a full-stack JavaScript framework for realtime
application development. One of Meteor's key features is that it gives
developers uniform methods for querying data on both the client and server.

<iframe width="640" height="430" src="https://www.youtube.com/embed/05R-TDP0Ltc?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
<!--more-->

Slarvae's Meteor integration includes a client-side cache that users can access
with conventional ReQL queries--derived from RethinkDB contributor [Michel
Tu's][michel] [ReQLite][] project. You can see a [sample application][sample]
built with Slarvae's bridge on GitHub. The Meteor integration is still at an
early stage of development, but it's off to a very promising start.

# LoopBack with RethinkDB

StrongLoop published a [blog post][slpost] that describes how to use RethinkDB
with [LoopBack][], their popular Node.js backend framework. LoopBack makes it
easy to build an API backend without implementing the endpoints by hand. It
automatically transforms simple data model definitions into a restful API with
standard CRUD operations.

In the blog post, StrongLoop shows how users can quickly build an API backend
with LoopBack and RethinkDB. The post also demonstrates how to use RethinkDB
changefeeds to add realtime capabilities to a LoopBack application. The
demonstration in the blog post uses developer Dmitry Gorbunov's [RethinkDB
connector][connector] for LoopBack.


[Install RethinkDB][install] to try out the new Meteor and LoopBack integrations.

[video]: https://www.youtube.com/watch?v=05R-TDP0Ltc
[ReQLite]: https://github.com/neumino/reqlite
[bridge]: https://github.com/Slarvae/meteor-rethinkdb
[sample]: https://github.com/Slarvae/meteor-rethinkdb-demo
[Slarvae]: https://github.com/Slarvae
[michel]: https://github.com/neumino
[slpost]: https://strongloop.com/strongblog/rethinkdb-connector-loopback-node-js-framework/
[LoopBack]: http://loopback.io/
[connector]: https://github.com/fuwaneko/loopback-connector-rethinkdb
[install]: http://rethinkdb.com/docs/install/
