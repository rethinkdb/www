---
layout: post
title: "Introducing Horizon: build realtime apps without writing backend code"
author: Ryan Paul
author_github: segphault
hero_image: 2016-05-17-horizon-launch.png
---

Today we are pleased to announce the first official release of
[Horizon][horizon.io], an open-source backend that lets developers build and
scale realtime web applications. Horizon includes:

* A **backend server** built with Node.js and RethinkDB that supports data persistence, realtime streams, input validation, user authentication, and permissions
* A **JavaScript client library** that developers can use on the frontend to store JSON documents in the database, perform queries, and subscribe to live updates
* A **command-line tool** that can generate project templates, start up a local Horizon development server, and help you deploy your Horizon application to the cloud

The Horizon server is a complete backend that developers can use to power their
applications. It's great for rapid prototyping: simply run the Horizon server
from the command-line and develop your frontend user experience with the Horizon
 client library. Frontend developers can use Horizon to create full applications
 without writing any backend code.

Horizon is open-source software, which means that you can use and modify it as
you see fit. Run a local instance on your laptop during development and then
deploy your application anywhere you want: low-cost VPS hosting environments,
scalable public cloud platforms, or your own bare metal. Horizon takes advantage
 of RethinkDB's [battle-tested clustering][], which makes it easy to scale as
your audience grows.
<!--more-->

Alongside the open-source Horizon backend, we're also building a cloud
management service for deploying, managing, and scaling Horizon applications.
[Horizon Cloud][] manages the Horizon backend and the underlying RethinkDB
database, scaling them up and down automatically as needed to accommodate
demand. Horizon Cloud also has built-in support for backup and restore,
no-downtime version updates, monitoring, and other useful features. Developers
will be able to deploy their application to Horizon Cloud with Horizon's
command-line tool. Horizon Cloud is currently in private beta, but you can
expect to see more details soon.

# Why Horizon?

When we introduced changefeeds in RethinkDB 1.16 last year, we shared our plan
for [advancing the realtime web][realtime-web]. Instead of polling for changes,
we made it possible for developers to tell the database to push a continuous
stream of live results to their application. When we shared this feature with
our users, one question came up over and over again: can I access RethinkDB's
live updates directly from a frontend web application running in the browser?

We originally designed changefeeds for backend developers, leaving it up to them
 to decide how to propagate realtime updates to frontend clients. Shortly after
we launched the feature, we started to think about the power of exposing
realtime data streams directly to the web browser. WebSocket abstraction
libraries, new data retrieval technologies like GraphQL, and powerful
asynchronous stream primitives like RxJS Observables promise new ways to
retrieve and manipulate data on the frontend. Web applications are evolving
beyond the stodgy legacy of conventional REST endpoints and ye olde
XMLHttpRequest. Horizon is built for that future, with realtime streaming from
the database to the frontend client.

Horizon reduces the amount of friction that developers face when they build and
scale web applications. It eliminates repetitive boilerplate and tedious steps
like hand-writing CRUD endpoints, authentication, and session management. We set
 out to flatten the space between the persistence layer and the frontend client,
 freeing the developer to focus on application logic instead of continually
reinventing the wheel.

# Get started with Horizon

To start working with Horizon today, install the [`horizon`][horizon-package]
package from NPM. The package includes the `hz` command-line tool, which you can
 use to generate and run your first project. You can find [detailed installation
 instructions][horizon-install] and an [introductory tutorial][horizon-getting-started] at the
[Horizon website][horizon.io].

The Horizon client library provides a fluent API that lets you express database
queries by chaining together methods. The queries return [RxJS][] Observables,
which make it easy to compose and manipulate streaming query results. Under the
hood, Horizon data collections are backed by RethinkDB tables. When you run
Horizon in development mode, the server automatically creates tables and indexes
 as needed.

The following example demonstrates how to use the Horizon client library from
the browser, or other frontend environment. The code shows how to store a JSON
document in a Horizon collection and fetch a filtered subset of the collection's
 records:

```javascript
var horizon = Horizon();
var messages = horizon("messages");

messages.store({
  sender: "Bob",
  time: new Date(),
  text: "Hello, World!"
});

messages.findAll({sender: "Bob"}).fetch()
        .subscribe(m => console.log(m));
```

To run a query continuously and get a stream of live updates for its result set,
 simply use the `watch` method. The following example shows how you can use a
Horizon query to build a realtime leaderboard for an online game:

```javascript
var users = horizon("users");

users.order("score", "descending").limit(5).watch()
     .subscribe(items => console.log(items))
```

The query above sorts the users by score in descending order and gives you the
first five. Every time that value changes, the `subscribe` callback will get a
complete array with the updated contents. It automatically maintains the sort
order and will add and remove users as needed.

The Horizon server translates client-side queries into [ReQL][], RethinkDB's
query language. The query translation takes advantage of automatically-generated
 indexes in order to maximize efficiency and performance. The Horizon query
language is designed to be simpler than ReQL so that it's easy for developers to
 learn and easy for the server to optimize. The following is a list of the
supported commands:

* find, findAll
* above, below, limit, order
* remove, removeAll
* store, upsert, replace
* watch, fetch

You can visit [Horizon's documentation][docs] to learn more about the client
library API. We're working on a number of improvements that will increase the
power and expressiveness of the query language, like a feature that will let you
 [combine multiple queries][model relations] to model relations.

# Integrating Horizon with the JavaScript ecosystem

Horizon isn't prescriptive or particularly opinionated--it's designed to work
well with the JavaScript frameworks that you already know and love. The Horizon
server is extensible, which means that developers who want to write custom
backend code can optionally embed Horizon in a Node.js application and add new
features as needed. You can even integrate Horizon with existing Node.js backend
 applications, where it will happily coexist alongside conventional frameworks
like Express, Koa, and Hapi.

Horizon's client library uses a simple WebSocket-based protocol to speak to the
server, but we provide a clean abstraction layer on top so that you don't have
to manage persistent connections or figure out how WebSockets work. You can use
the Horizon client library with any frontend framework--it works equally well
with React, Angular, Ember, and vanilla JavaScript. You can also use it with
popular frontend state managers like Redux.

You can find a [selection of examples][examples] that demonstrate how to
integrate Horizon with various frontend and backend frameworks in the official
Horizon GitHub repository. React developers might also want to check out
[lovli.js][], a helpful boilerplate created by community member
[Patrick Neschkudla][flipace-gh] that brings together Horizon, React, and Redux.

We look forward to bringing native Horizon client libraries to mobile platforms
at some point in the future. We're also actively
[working with our community][rn-discuss] to make sure that the Horizon
JavaScript client library works in environments like Electron and React Native.
JavaScript is making inroads everywhere, from embedded IoT systems to desktop
and mobile applications. We think that Horizon has a lot to offer in all of the
places that developers choose JavaScript.

We're also documenting the [underlying protocol][protocol] that our client
library uses to communicate with the Horizon backend. Developers can use the
protocol to build their own client library implementations on other programming
languages. The protocol consists of simple JSON documents. It's built on top of
[engine.io][], a realtime framework that supports multiple network transports.

# Roadmap

Today's Horizon release is a starting point rather than the final destination.
You can expect to see new features and major improvements as the project
advances. The [features available today][available today] include: queries, live
 updates, authentication, permissions, and support for serving static assets.

Some of the flagship features are less mature than others. The permission system
 and support for validation are recent additions, features that landed very late
 in the development cycle. You might encounter some rough edges as we work to
refine those features and incorporate further improvements.

The long-term roadmap is still evolving, but the following is a brief list of
features that we'd like to include in future releases of Horizon:

* A [built-in admin dashboard][hzadmin] with an interactive data browser
* Better [connection lifecycle management][issue-reconnect] and disconnect recovery
* Support for [building your own Horizon commands][issue-endpoints] with ReQL and JavaScript
* Support for [handling file uploads][issue-uploads] from the client
* Conventional [password authentication][issue-password] in addition to OAuth providers
* A built-in [pagination API][issue-pagination] that works with realtime queries
* Native support for performing [optimistic updates][issue-optimistic]
* Support for relations via [query aggregation][model relations]
* Built-in support for [fetching data with GraphQL][issue-graphql]

You can expect to see routine status updates in the [Horizon forum][forum] as we
 work towards completing these features and stabilizing the Horizon code base.

# Community participation

During the earliest stages of our work on Horizon, we invited members of the
RethinkDB community to participate and provide feedback. The developer preview
amassed well over 1,700 contributors testing, building, and adding features to
Horizon prior to today's launch. The feedback and code contributions we received
 from those users helped drive Horizon development, shaping the project's
feature set and developer ergonomics.

We're opening Horizon up to everyone today so that more people can get involved
and join the community. We're eager to hear your feedback and feature requests.
There are several places where you can reach us and other members of the
community:

* The [Horizon.io website][horizon.io]
* The official [Horizon forum][forum]
* The [Horizon project][repo] and issue tracker on GitHub
* The #horizon channel in our [RethinkDB Slack group][slack]
* Follow us on Twitter: [@horizonjs][twitter]

We're looking forward to working with you as we continue our effort to advance
the realtime web.

[horizon-install]:  https://horizon.io/install
[horizon-getting-started]: https://horizon.io/docs/getting-started
[horizon-package]: https://www.npmjs.com/package/horizon
[realtime-web]: https://rethinkdb.com/blog/realtime-web/
[battle-tested clustering]: https://aphyr.com/posts/329-jepsen-rethinkdb-2-1-5
[rn-discuss]: https://discuss.horizon.io/t/remaining-work-for-react-native/106
[lovli.js]: https://github.com/flipace/lovli.js
[examples]: https://github.com/rethinkdb/horizon/tree/next/examples
[model relations]: https://github.com/rethinkdb/horizon/issues/105
[RxJS]: https://github.com/Reactive-Extensions/RxJS
[ReQL]: https://rethinkdb.com/docs/introduction-to-reql/
[horizon.io]: http://horizon.io
[forum]: https://discuss.horizon.io/
[repo]: https://github.com/rethinkdb/horizon
[slack]: http://slack.rethinkdb.com/
[twitter]: https://twitter.com/horizonjs
[available today]: https://discuss.horizon.io/t/the-road-to-1-0/28
[hzadmin]: https://github.com/rethinkdb/horizon/issues/154
[issue-reconnect]: https://github.com/rethinkdb/horizon/issues/358
[issue-endpoints]: https://github.com/rethinkdb/horizon/issues/337
[issue-uploads]: https://github.com/rethinkdb/horizon/issues/186
[issue-password]: https://github.com/rethinkdb/horizon/issues/176
[issue-pagination]: https://github.com/rethinkdb/horizon/issues/31
[issue-optimistic]: https://github.com/rethinkdb/horizon/issues/23
[issue-graphql]: https://github.com/rethinkdb/horizon/issues/125
[flipace-gh]: https://github.com/flipace
[protocol]: https://github.com/rethinkdb/horizon/blob/next/docs/protocol.md
[engine.io]: https://github.com/socketio/engine.io
[Horizon Cloud]: http://horizon.io/cloud
[docs]: http://horizon.io/docs
