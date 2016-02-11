---
layout: post
title: "Go driver for RethinkDB hits 1.0, production-ready"
author: Segphault
author_github: segphault
hero_image: 2015-07-02-go-banner.png
---

[Dan Cannon][dan]'s [GoRethink][] project provides a RethinkDB driver for
the Go language. Earlier this week, Dan [released GoRethink 1.0][release]
and announced that the driver is now ready for use in production
environments.

GoRethink is among the most popular and well-maintained third-party client
drivers for RethinkDB. It supports the latest RethinkDB features while
offering clean integration between ReQL and Go's native syntax. In
addition to standard driver functionality, GoRethink also includes a
number of advanced features like connection pooling.

<!--more-->

I first wrote about GoRethink back in February, when I published a
[tutorial][] that demonstrates how to build an IRC bot with Go and
RethinkDB changefeeds. I also [showed how to build][monitordemo] realtime
web applications with GoRethink by broadcasting changefeed updates over
Socket.io.

Alongside various fixes and improvements, the GoRethink 1.0 release also
features some minor API changes that make capitalization more consistent
with Go conventions. Be sure to take those differences into account when
reading the tutorial linked above and other content written for older
versions of the driver.

Go's native concurrency features make the language particularly
well-suited for realtime web applications. I've also found that Go's
[nested structs][structs] offer a relatively painless way to work with
complex JSON documents without giving up type safety. GoRethink makes good
use of the language's strengths, which can help to boost developer
productivity.

Want to try it yourself? [Install RethinkDB][install] and check out the
[official GoRethink documentation][gorethinkdocs].

[dan]: https://twitter.com/_dancannon
[GoRethink]: https://github.com/dancannon/gorethink
[release]: https://github.com/dancannon/gorethink/releases/tag/v1.0.0
[tutorial]: http://rethinkdb.com/blog/go-irc-bot/
[structs]: https://talks.golang.org/2012/10things.slide#4
[monitordemo]: https://github.com/rethinkdb/rethink-status/tree/go-backend
[gorethinkdocs]: https://github.com/dancannon/gorethink/wiki
[install]: http://rethinkdb.com/docs/install/
