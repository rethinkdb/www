---
layout: post
title: A tool for RethinkDB driver developers
tags:
- drivers
author: Alex Popescu
author_github: http://github.com/al3xandru

---

The [main focus of the 1.4 release][release] was to refactor the client-server
wire protocol to simplify future development of the query language and also to
make writing client drivers for new languages significantly easier.

It's been a bit over a month since the release and we've already heard of a
couple of new drivers being developed.
[Erlang](https://github.com/taybin/lethink),
[C#](https://github.com/mfenniak/rethinkdb-net), Scala, and the just-announced
[PHP](http://danielmewes.github.io/php-rql/) are  the ones we know about, but
we hope to hear from you about even more of them!

This seemed like a  confirmation that a [refactored, simplified and source
documented protobuf
definition](https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/ql2.proto)
and the rewritten official drivers were indeed what was needed to enable users
to start working on new drivers.  But we realized, and our users helped us with
this, that while being a good start, these do not (and can not) provide all the
details needed while developing new drivers.

To make things even simpler, [Michel](https://github.com/neumino) wrote a 
[Python library that exposes all the details of the RethinkDB client server protocol][project-github]. 
Basically you can write a query and this library will show:

- the Protobuf client message
- the serialized message
- the serialized response
- the Protobuf server response

All the details of setting it up and using it are explained in the [readme
file][project-github]. Have fun with it and thanks for bringing RethinkDB to
other languages!

[release]: /blog/rethinkdb-1.4-release/ "RethinkDB 1.4: improved wire protocol, updated drivers, data explorer history"

[project-github]: https://github.com/neumino/rethinkdb-driver-development "A tool to help users create a new driver for RethinkDB"
