---
layout: post
title: The benchmark you're reading is probably wrong
--- 

Mikeal Rogers wrote a [blog post][] on MongoDB performance and durability. In
one of the sections, he writes about the request/response model, and makes the
following statement:

[blog post]: http://www.futurealoof.com/posts/mongodb-performance-durability.html

_MongoDB, by default, doesn't actually have a response for writes._

In response, one of 10gen employees (the company behind MongoDB) made the
following comment on Hacker News:

_We did this to make MongoDB look good in stupid benchmarks._
<!--more-->

The [benchmark][] in question shows a single graph, which demonstrates that
MongoDB is 27 times faster than CouchDB on inserting one million rows. At the
first glance, the benchmark immediately looks silly if you've ever done serious
benchmarking before. CouchDB people are smart, inserting such a small number of
elements is a relatively simple feature, and it's almost certain that either
they would have fixed something that simple or they had a very good reason not
to (in which case the benchmark is likely measuring apples and oranges).

[benchmark]: http://www.snailinaturtleneck.com/blog/2009/06/29/couchdb-vs-mongodb-benchmark/

Let's do some back of the envelope math. Roundtrip latency on a commodity
network for a small packet can range from 0.2ms to 0.8ms. A single rotational
drive can do 15000RPM / 60sec = 250 operations per second (resulting in close
to 5ms latency in practice), and a single Intel X25-m SSD drive can do about
7000 write operations per second (resulting in close to 0.15ms latency).

The benchmark demonstrates that CouchDB takes an average of 0.5ms per document
to insert one million documents, while MongoDB does the same in 0.01ms.
Clearly the rotational drives are too slow to play a part in the measurement,
and the SSD drives are probably too fast to matter for CouchDB and too slow to
matter for MongoDB. However, CouchDB appears to be awfully close to commonly
encountered network latencies, while MongoDB inserts each document 50 times
faster than commodity network latency.

At first observation, it appears likely that the CouchDB client library is
configured to wait for the socket to receive a response from the database
server before sending the next insert, while the MongoDB client is configured
to continue sending insert requests without waiting for a response. If this is
true, the benchmark compares apples and oranges and tells you absolutely
nothing about which database engine is actually faster at inserting elements.
It doesn't measure how fast each engine handles insertion when the dataset fits
into memory, when the dataset spills onto disk, or when there are multiple
concurrent clients (which is a whole different can of worms). It doesn't even
begin to address the more subtle issues of whether the potential bottlenecks
for each database might reside in the virtual memory configuration, or the file
system, or the operating system I/O scheduler, or some other part of the stack,
because each database uses each one of these components slightly differently.
What the benchmark likely measures is something that is never mentioned - the
latency of the network stack for CouchDB, and something entirely unrelated for
MongoDB.

Unfortunately most benchmarks published online have similar crucial flaws in
the methodology, and since many people make decisions based on this
information, software vendors are forced to modify the default configuration of
their products to look good on these benchmarks. There is no easy
solution--performing proper benchmarks is very error-prone, time consuming
work. It's good to be very skeptical about benchmarks that show a large
performance difference but don't carefully discuss the methodology and
potential pitfalls.  As Brad Pitt's character says at the end of Inglourious
Basterds, _"Long story short, we hear a story too good to be true, it ain't"_.
