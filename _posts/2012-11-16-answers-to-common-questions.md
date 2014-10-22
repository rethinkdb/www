---
layout: post
title: Answers to common questions about RethinkDB
tags:
- faq
author: Alex Popescu
author_github: http://github.com/al3xandru
--- 

We received a lot of questions in past few days since [our
release](http://news.ycombinator.com/item?id=4763879). While my colleagues
are busy expanding [support for other Linux
distros](http://www.rethinkdb.com/docs/install/), [squashing
bugs](https://github.com/rethinkdb/rethinkdb), and improving the
[documentation](http://www.rethinkdb.com/docs), I thought I'd use this
time to answer some of the most common questions we received.

# How do I install RethinkDB on other Linux flavors?

Currently the only binaries we provide are for **Ubuntu 64-bit 11.04 and
above**. While we are working on packaging for other Linux flavors, you can
try [building from source](http://www.rethinkdb.com/docs/build/).

# What's the best method to install on OS X?

_Update_: Starting with version 1.3, [released mid December 2012](/blog/rethinkdb-13-release),
there's a pre-built package distribution Mac OS X . You can also install RethinkDB
using Homebrew. For detailed instructions check out the [install page](/docs/install/).

Right now there are two options:

1. [installing the Ubuntu package](http://www.rethinkdb.com/docs/install/)
   in a virtual machine running Ubuntu 64-bit.
2. using [@RyanAmos](https://github.com/RyanAmos)'s
   [vagrant](http://vagrantup.com/)-based setup
   <https://github.com/RyanAmos/rethinkdb-vagrant>.

Because neither of these options is as easy as we would like it to be, nor
pleasant, we decided to  [work on a native OS X
port](https://github.com/rethinkdb/rethinkdb/issues/5#issuecomment-10302744).

This question was asked by so many people that most probably I'll fail to
mention everyone: [Ollivier Robert](https://twitter.com/Keltounet),
[Max Countryman](http://twitter.com/MaxCountryman),
[@seanhess](http://twitter.com/seanhess). But you all helped us decide to
work on the Mac OS X port now.

# Is there a driver/library for X?

The first release included only  [3
drivers](http://www.rethinkdb.com/docs/guides/drivers/): Javascript,
Python, and Ruby.  But the list of drivers we've been asked about keeps
growing: Java, Erlang, C++, Go, PHP, Arc, Perl, C#/.NET, Coffescript, Dart,
Scala.

We use [protocol buffers](http://code.google.com/p/protobuf/) between the
client drivers and the server, so adding support for other languages
should be easy with your help. [Etienne
Laurin](http://twitter.com/atnnn)  has already been working on a [Haskell
client](https://github.com/atnnn/haskell-rethinkdb).
 
While writing our initial drivers we've realized that
[query_language.proto](https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/query_language.proto)
could be significantly improved, so in the next couple of weeks there will be
some changes that will simplify writing client libraries. We also want to
clearly document the process of creating new drivers to help contributors and
speed development on other languages.
 
# Are there any plans for an HTTP interface?

This question came from [Edgardo Vega](https://twitter.com/CasaDeVega).
The RethinkDB query language is so simple, expressive, and pleasant, that
trying to make it available over HTTP would be quite difficult and a
disservice to users.

If  you are building an application that needs HTTP access to RethinkDB,
we are sure that creating a RESTful interface that fits your needs would
be a better solution than exposing the [complete ReQL
language](http://www.rethinkdb.com/api/) over HTTP.

# Does RethinkDB have support for geo/spatial?

[Smart Mumbaikar](https://twitter.com/smart_mumbaikar) was wondering if
RethinkDB handles geo data. 

Unfortunately there is currently no support for that. You could still
insert geo data in RethinkDB's JSON engine, but we know that without
geospatial indexes this won't be very useful.

# Can RethinkDB do bulk inserts?

[Sergio Tulentsev](https://twitter.com/stulentsev) asked about bulk
inserts.  The way to do bulk inserts is by passing an array to the
`insert` function. Here is how to do it in
[Javascript](http://www.rethinkdb.com/api/#js:writing_data-insert):

```javascript
r.table('marvel').insert([
	{ superhero: 'Wolverine', superpower: 'Adamantium' }, 
	{ superhero: 'Spiderman', superpower: 'spidy sense' }]).run()
```

Bulk inserts in [Python](http://www.rethinkdb.com/api/#py:writing_data-insert)
and [Ruby](http://www.rethinkdb.com/api/#rb:writing_data-insert) look exactly
the same. Another way to get data into RethinkDB is by importing CSV files:

`rethinkdb import --join localhost:29015 --table <DB_NAME.TABLE_NAME> --input-file<FILE>`

# Does RethinkDB support upserts?

Another question from [Sergio Tulentsev](https://twitter.com/stulentsev). The
first public release didn't include support for upserts, but now it can be
done by passing an extra flag to `insert`:

```javascript
r.table('marvel').insert({ superhero: 'Iron Man', superpower: 'Arc Reactor' }, {upsert: true}).run()
```

When set to `true`, the new document from `insert` will overwrite  the
existing one.

# Why doesn't RethinkDB include Stargate SG-1 in their list of best TV shows?

[Hilario P&eacute;rez Corona](https://twitter.com/hpcorona) put us in a delicate
position with  this question on Twitter. I did a search against our commit
logs and found no references to Stargate SG-1. Future updates will make
sure to address this very serious omission on our side.

---

If you have any additional questions please reach out to us on
[Twitter](http://twitter.com/rethinkdb),
[IRC](irc://chat.freenode.net/#rethinkdb), or our [Google
group](http://groups.google.com/group/rethinkdb).
