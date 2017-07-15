---
layout: post
title: Answers to common questions about RethinkDB
author: Alex Popescu
author_github: al3xandru
--- 

___Note: this is a blog post from November 2012, and much of the information
here is outdated. RethinkDB has [official packages][install] for Ubuntu,
Centos, Debian, and OS X (both prebuilt and via Homebrew); current versions of
RethinkDB use a [JSON-based protocol][driver-spec] rather than Protobufs; in
addition to the official client drivers for Python, Ruby and JavaScript, we
have [community-supported drivers][drivers] for a variety of languages
including C#, Clojure, Dart, Go, Haskell, Java, Lua, Perl, PHP and Scala;
RethinkDB has [geospatial support](); and while RethinkDB supports "upserts,"
the [insert][] command now uses a different syntax.___

[install]: /docs/install/
[driver-spec]: /docs/driver-spec/
[drivers]: /docs/install-drivers
[geo]: /docs/geo-support/
[insert]: /api/javascript/insert

We received a lot of questions in past few days since [our release][hn]. While
my colleagues are busy expanding [support for other Linux distros][install],
[squashing bugs][github], and improving the [documentation][docs]), I thought
I'd use this time to answer some of the most common questions we received.
<!--more-->

[hn]: http://news.ycombinator.com/item?id=4763879
[install]:/docs/install/ 
[github]: https://github.com/rethinkdb/rethinkdb
[docs]: /docs

# How do I install RethinkDB on other Linux flavors?

Currently the only binaries we provide are for **Ubuntu 64-bit 11.04 and
above**. While we are working on packaging for other Linux flavors, you can try
[building from source][build].

[build]: /docs/build

# What's the best method to install on OS X?

_Update_: Starting with version 1.3, [released mid December 2012][],
there's a pre-built package distribution Mac OS X . You can also install RethinkDB
using Homebrew. For detailed instructions check out the [install page][install].

[1.3-release]: /blog/rethinkdb-13-release
[install]: /docs/install/

Right now there are two options:

1. [installing the Ubuntu package][install] in a virtual machine running Ubuntu
   64-bit.
2. using [@RyanAmos][]'s [vagrant][]-based setup:
   <https://github.com/RyanAmos/rethinkdb-vagrant>.

[install]: /docs/install
[@RyanAmos]: https://github.com/RyanAmos
[vagrant]: http://vagrantup.com/

Because neither of these options is as easy as we would like it to be, nor
pleasant, we decided to  [work on a native OS X port][osx].

[osx]: https://github.com/rethinkdb/rethinkdb/issues/5#issuecomment-10302744

This question was asked by so many people that most probably I'll fail to
mention everyone: [Ollivier Robert][@Keltounet], [Max
Countryman][@MaxCountryman], [@seanhess][]. But you all helped us decide to
work on the Mac OS X port now.

[@Keltounet]: https://twitter.com/Keltounet
[@MaxCountryman]: http://twitter.com/MaxCountryman
[@seanhess]: http://twitter.com/seanhess

# Is there a driver/library for X?

The first release included only  [3 drivers](): Javascript, Python, and Ruby.
But the list of drivers we've been asked about keeps growing: Java, Erlang,
C++, Go, PHP, Arc, Perl, C#/.NET, Coffescript, Dart, Scala.

[3 drivers]: http://www.rethinkdb.com/docs/guides/drivers/

We use [protocol buffers][] between the client drivers and the server, so
adding support for other languages should be easy with your help. [Etienne
Laurin][@atnnn]  has already been working on a [Haskell client][haskell].

[protocol buffers]: http://code.google.com/p/protobuf/
[@atnnn]: http://twitter.com/atnnn
[haskell]: https://github.com/atnnn/haskell-rethinkdb
 
While writing our initial drivers we've realized that
[query_language.proto][proto] could be significantly improved, so in the next
couple of weeks there will be some changes that will simplify writing client
libraries. We also want to clearly document the process of creating new drivers
to help contributors and speed development on other languages.

[proto]: https://github.com/rethinkdb/rethinkdb/blob/next/src/rdb_protocol/query_language.proto
 
# Are there any plans for an HTTP interface?

This question came from [Edgardo Vega][@CasaDeVega].
The RethinkDB query language is so simple, expressive, and pleasant, that
trying to make it available over HTTP would be quite difficult and a
disservice to users.

[@CasaDeVega]: https://twitter.com/CasaDeVega

If you are building an application that needs HTTP access to RethinkDB, we are
sure that creating a RESTful interface that fits your needs would be a better
solution than exposing the [complete ReQL language][api] over HTTP.

[api]: http://www.rethinkdb.com/api/

# Does RethinkDB have support for geo/spatial?

[Smart Mumbaikar][@smart_mumbaikar] was wondering if RethinkDB handles geo
data. 

[@smart_mumbaikar]: https://twitter.com/smart_mumbaikar 

Unfortunately there is currently no support for that. You could still insert
geo data in RethinkDB's JSON engine, but we know that without geospatial
indexes this won't be very useful.

# Can RethinkDB do bulk inserts?

[Sergio Tulentsev][@stulentsev] asked about bulk inserts.  The way to do bulk
inserts is by passing an array to the `insert` function. Here is how to do it
in [JavaScript][insert-js]:

[@stulentsev]: https://twitter.com/stulentsev
[insert-js]: http://www.rethinkdb.com/api/#js:writing_data-insert

```javascript
r.table('marvel').insert([
	{ superhero: 'Wolverine', superpower: 'Adamantium' }, 
	{ superhero: 'Spiderman', superpower: 'spidy sense' }]).run()
```

Bulk inserts in [Python][insert-py] and [Ruby][insert-rb] look exactly the
same. Another way to get data into RethinkDB is by importing CSV files:

[insert-py]: http://www.rethinkdb.com/api/#py:writing_data-insert
[insert-rb]: http://www.rethinkdb.com/api/#rb:writing_data-insert

`rethinkdb import --join localhost:29015 --table <DB_NAME.TABLE_NAME> --input-file<FILE>`

# Does RethinkDB support upserts?

Another question from [Sergio Tulentsev][@stulentsev]. The first public release
didn't include support for upserts, but now it can be done by passing an extra
flag to `insert`:

[@stulentsev]: https://twitter.com/stulentsev

```javascript
r.table('marvel').insert({ superhero: 'Iron Man', superpower: 'Arc Reactor' }, {upsert: true}).run()
```

When set to `true`, the new document from `insert` will overwrite  the existing
one.

# Why doesn't RethinkDB include Stargate SG-1 in their list of best TV shows?

[Hilario P&eacute;rez Corona][@hpcorona] put us in a delicate position with
this question on Twitter. I did a search against our commit logs and found no
references to Stargate SG-1. Future updates will make sure to address this very
serious omission on our side.

[@hpcorona]: https://twitter.com/hpcorona

If you have any additional questions please reach out to us on [Twitter][],
[IRC][], or our [Google group][].

[Twitter]: http://twitter.com/rethinkdb
[IRC]: irc://chat.freenode.net/#rethinkdb
[Google group]: http://groups.google.com/group/rethinkdb
