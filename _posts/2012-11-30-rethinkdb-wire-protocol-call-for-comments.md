---
layout: post
title: Call for comments - RethinkDB wire protocol
published: true
tags:
- protobuf
- ReQL
---


When version 1.2 was released, we were [surprised (and delighted) by how many
people](http://news.ycombinator.com/item?id=4763879) asked about writing
RethinkDB clients in their language.  RethinkDB's query language (ReQL) is
encoded using Google's Protocol Buffers, which are available in many languages.
So writing a client should have been relatively easy, at least in theory.  In
practice, [our first Protobuf
spec](https://github.com/rethinkdb/rethinkdb/blob/1451f83cabf412484d2db2e9a49ab6f30c41d0c5/src/rdb_protocol/query_language.proto)
was a mess.  It accreted a number of hacks and inconsistencies as the scope of
the query language grew, and the scramble to release didn't help matters.

# The new spec

The task of designing a new spec fell to the guys--that's
[wmrowan](https://github.com/wmrowan) and me
([mlucy](https://github.com/mlucy))--that wrote and maintained the first client
libraries. After some thought we decided that the [old
spec](https://github.com/rethinkdb/rethinkdb/blob/1451f83cabf412484d2db2e9a49ab6f30c41d0c5/src/rdb_protocol/query_language.proto)
did too much, and was too complicated.  (See below for more details.)  

**[The new
spec](https://github.com/rethinkdb/rethinkdb/wiki/protobuf_rfc_raw_spec)** aims
to be drastically simpler **[[1](#fn-simpler-proto-spec)]**.  Writing a client
for it should be as easy as possible.  Toward that end, we're putting out a
[Request For Comments on the new
spec](https://github.com/rethinkdb/rethinkdb/wiki/protobuf_rfc).  Are you
thinking of writing a driver?  We'd love to hear from you, especially about
where the new spec is confusing, or ways you think it could be better.  (The
easiest way to give feedback is to open an issue at
[https://github.com/rethinkdb/rethinkdb/issues](https://github.com/rethinkdb/rethinkdb/issues).)

# The thought process

The original Protobuf spec tried to enforce the constraints of ReQL in the
structure of the Protobuf.  This sounded like a good idea, but led to a number
of problems in practice.

## Problem 1: Inscrutable error messages

Mistakes in the clients led to inscrutable error messages.  Let's say you're
writing a client in a dynamic language, and you forget to check that the
arguments to `pick` are strings.  Your internal representation of a `pick`
query is constructed just fine (since you forgot to check).  Later, when you
convert your internal representation into a Protobuf to send to the server, the
Protobuf library tries to put a non-string into a string.  Now there are a few
possible scenarios:

  1. The Protobuf library may convert the non-string to a string and run a
     query the user never intended.
  2. The Protobuf library may freak out and give the user an inscrutable
     internal error.
  3. The Protobuf library may create an invalid Protobuf that is rejected by
     the server with a useless error along the lines of "I couldn't parse
     that!".

The third case is unlikely when trying to put a non-string into a string, but
I've seen it happen in several more complicated cases.

**Solution**: The new Protobuf spec encodes fewer constraints, and those
constraints are checked on the server instead
**[[2](#fn-new-protobuf-version)]**.  In the above scenario, the malformed
query would probably reach the server and be rejected with a sensible, readable
error message.  Clients that support backtraces (all of the current ones do)
would even show the user what part of their query was malformed.

## Problem 2: Too many corner cases

There was a profusion of special cases.  This turned the clients into,
essentially, libraries of special cases.  

**Solution**: In essence, the new spec is just structured expressions (modulo
some details like optional arguments).  It's centered around a **term** (the
body of a query) which is either:

  1. a basic **datatype**
  2. an **operator** that acts on:
    * an **array of other terms** (its positional arguments, like the numbers
      in `r.add(1,2)`)
    * an **array of \<string, term\> tuples** (its optional arguments, like the
      flag in `r.table('tbl', {:use_outdated => true})`)

In case you're wondering at this point why we're using Protobufs at all, there
are two main reasons:

  * **Space savings**: Protobufs are very efficient on the wire.
  * **Backward compatibility**:
    If an operator's behavior changes, its number in the Protobuf spec can also
    change, and the server can continue to support the old behavior.
    (In fact, old clients pointed at the new server wouldn't even see a
    difference.)

## Problem 3: Backtraces

Dealing with backtraces was a nightmare. The old backtraces were absurdly bad,
even taking into account the randomness of the Protobuf spec.  Sometimes they
corresponded to parts of the Protobuf.  Sometimes they corresponded to the
indexes of positional arguments.  Sometimes they corresponded to both at once
(like "bind:3").  Sometimes they corresponded to someone's sense of what was
semantically important.  Sometimes terms were simply skipped, or included when
they weren't necessary.  In the end, client libraries had to clean up the whole
mess before showing anything to users.  (If you have a strong stomach, you can
see my attempt to tame the madness in the Ruby driver
[here](https://github.com/rethinkdb/rethinkdb/blob/5a745c29522a9e5de23ec108df2685c8e6ef7c9a/drivers/ruby/lib/bt.rb#L54).).

**Solution**: Backtraces are now a list of either indexes into positional
arguments or keys for optional arguments.  There will (hopefully) be no
ambiguity or randomly omitted frames. It should be as easy as possible for
people writing their own clients to include the pretty-printed backtraces in
the current 3 clients.  

# Where are we now? ##

The new proposed spec is available
[here](https://github.com/rethinkdb/rethinkdb/wiki/protobuf_rfc_raw_spec). We'd
appreciate all feedback about any confusing aspects of it or unnecessary
complexity that someone implementing a client would have to deal with. 

The easiest way to give us feedback is to open an issue at
<https://github.com/rethinkdb/rethinkdb/issues>.

## Additional notes

**[<a name="fn-simpler-proto-spec">1</a>]** Just to be clear, this isn't a
"dumb client, smart server" thing.  The old system was basically "smart client,
smart wire format, smart server".  The new one is "smart client, dumb wire
format, smarter server".  Normally "dumb client, smart server" is good
engineering.  Here, though, having a smart client sometimes lets the client
error when people *construct* a query, rather than when they run it.  Queries
failing early helps users so much that it's worth putting up with the
engineering problems that surround smart clients.

**[<a name="fn-new-protobuf-version">2</a>]** The server currently doesn't
support the new Protobuf spec.  Our (extremely tentative) estimate is that it
should support the new spec sometime in January.  If that sounds like a long
time, it's because:

  1. We want to spend some time gathering comments so we know the new spec
     makes sense to people.
  2. We're going to be refactoring lots of the query language code on the
     server (since everything will be broken anyway).
  3. Christmas!
  4. We'd like to have a better test infrastructure to run the new code through
     its paces before we replace the current, battle-hardened version.
