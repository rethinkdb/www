---
layout: post
title: "Built with RethinkDB: secure note-taking app Turtl"
author: Segphault
author_github: segphault
hero_image: 2016-02-05-turtl-banner.png
---

[Turtl][] is an open source note-taking application built with RethinkDB.
It uses encryption to protect user content, which can include notes,
passwords, bookmarks, and images. Turtl is the creation of developer
[Andrew Lyon][]. Users can download the source code and run their own
instance of the application, or they can register an account on a [hosted
service][] operated by Andrew's independent software company.

Turtl's API backend is implemented in Common Lisp, with an intriguing
stack that Andrew largely built himself. He created his own asynchronous
HTTP server framework called [Wookie][], which is powered by an
event-driven [asynchronous IO library][cl-async] that he wrote on top of
Node's [libuv][]. He also made his own
[Common Lisp RethinkDB client driver][cl-rethinkdb], which the Turtl backend
uses to communicate with a RethinkDB cluster for data persistence.

<!--more-->

The Turtl user interface is built with JavaScript and HTML. Although it's
built with web technologies, there's no browser-based frontend [for
various security reasons][no-web]. Users can install desktop and mobile
clients, which all provide thin native wrappers around the web content. On
the desktop, the client is built with [NW.js][], which combines a Node
runtime and Blink-based HTML rendering engine. There's also a
Cordova-based [Android client][android], with support for iOS planned in
the future.

The client application synchronizes with the backend, [using encryption][]
to securely store and transmit data. On the client side, it keeps
the user's data in IndexedDB. Each individual note and board has its
own encryption key, which makes it possible for multiple users to
[securely share][] boards with other users.

When the user runs the Turtl client application, they can configure it
with the address of the backend server that it should use for
synchronization. By default, it will point to the hosted service, but
users can easily give it the address of their own self-hosted instance.

The Turtl note list uses a Pinterest-style dynamic grid, with staggered
blocks that are reflow to fit the space. Users can hit the plus button on
the bottom right-hand corner in order to add a new item. The application
supports Markdown for formatted text content. When authoring a note, the
user can optionally add tags and assign it to a board. The application
includes several other noteworthy features, including full-text search.

<img src="/assets/images/posts/2016-02-05-turtl-ui.png">

The roadmap for [upcoming features][] includes support for importing and
exporting notes and integration with platform sharing features in the
mobile clients. You can follow Turtl feature development by visiting the
[project's Trello board][trello].

Want to run your own instance of Turtl? Start by
[installing RethinkDB][install] and then check out the
[setup instructions][] on the Turtl website.

[Turtl]: https://turtl.it/
[clr]: https://github.com/orthecreedence/cl-rethinkdb
[Wookie]: http://wookie.lyonbros.com/
[Andrew Lyon]: https://github.com/orthecreedence
[cl-async]: https://github.com/orthecreedence/cl-async
[libuv]: https://github.com/libuv/libuv
[cl-rethinkdb]: https://github.com/orthecreedence/cl-rethinkdb
[NW.js]: http://nwjs.io/
[hosted service]: https://turtl.it/pricing/
[no-web]: http://turtlapp.tumblr.com/post/118259491304/why-not-just-publish-turtl-as-a-web-app
[android]: https://github.com/turtl/mobile
[using encryption]: https://turtl.it/docs/security/encryption-specifics/
[securely share]: https://turtl.it/docs/architecture/#sharing
[trello]: https://trello.com/b/yIQGkHia/turtl-product-dev
[upcoming features]: http://turtlapp.tumblr.com/post/137203111884/look-forward-to-these-features
[setup instructions]: https://turtl.it/docs/server/
[install]: /docs/install/
