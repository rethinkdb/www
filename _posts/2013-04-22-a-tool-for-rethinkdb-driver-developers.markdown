---
layout: post
title: A tool for RethinkDB driver developers
tags:
- drivers
author: Alex Popescu
author_github: al3xandru

---

The [main focus of the 1.4 release][release] was to refactor the client-server
wire protocol to simplify future development of the query language and also to
make writing client drivers for new languages significantly easier.

[release]: /blog/rethinkdb-1.4-release/ 

It's been a bit over a month since the release and we've already heard of a
couple of new drivers being developed.  [Erlang][], [C#][], Scala, and the
just-announced [PHP][] are  the ones we know about, but we hope to hear from
you about even more of them!

[Erlang]: https://github.com/taybin/lethink
[C#]: https://github.com/mfenniak/rethinkdb-net
[PHP]: http://danielmewes.github.io/php-rql/

This seemed like a  confirmation that a refactored, simplified and source
documented [protobuf definition][] and the rewritten official drivers were
indeed what was needed to enable users to start working on new drivers.  But we
realized, and our users helped us with this, that while being a good start,
these do not (and can not) provide all the  details needed while developing new
drivers.
<!--more-->

[protobuf definition]: https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/ql2.proto

To make things even simpler, [@neumino][] wrote a [Python
library][project-github] that exposes all the details of the RethinkDB client
server protocol.  Basically you can write a query and this library will show:

[@neumino]: https://github.com/neumino

- the Protobuf client message
- the serialized message
- the serialized response
- the Protobuf server response

All the details of setting it up and using it are explained in the [readme
file][project-github]. Have fun with it and thanks for bringing RethinkDB to
other languages!

[project-github]: https://github.com/neumino/rethinkdb-driver-development
