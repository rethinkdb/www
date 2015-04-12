---
layout: post
title: RethinkDB performance data
tags: 
- benchmarks
--- 

It's been a busy and exciting week since we announced RethinkDB. Of all the
feedback we received, the most common request was for performance numbers.
Before the launch our top priority was correctness. We spent most of our time
testing RethinkDB with Wordpress and adding the missing features. As a result,
performance suffered. In the past week we tuned the engine back up to high
performance. We're still far from finished with the improvements we want to
make, but we feel that we've reached a level of performance we can be proud to
display.
<!--more-->

We wrote our original benchmarking tool in Python, but during our latest
benchmarks, we noticed that it was taking about as much time as the engine
itself, hiding our real performance numbers. We now have a very small
Objective-C program (<900 lines) that uses prepared statements in a tight loop,
and times only across the `mysql_stmt_execute()` call.  For inserts, the
benchmark creates a table with three `INT` columns, two being indexed, and
performs N random (non- duplicate) INSERTs `(k,k,k)` in a loop.  For selects,
it performs N random indexed point queries. An optional number of SELECT
threads run as well, each thread doing repeated indexed point queries
throughout execution of the main timed thread.

The benchmarks were run on a 2.5 GHz Pentium Core 2 Duo machine with 2 GB RAM,
on a 16 GB SUPER TALENT MasterDrive, an MLC solid state drive, connected via a
3 GB SATA II bus. RethinkDB and MyISAM were run with the stock config options.
We ran the InnoDB test by starting the server with
`--innodb_flush_log_at_trx_commit=0 --innodb_support_xa=0
--innodb_buffer_pool_size=1536M`.

Here are the results:

![RethinkDB performance data.](/assets/images/posts/2009-08-12-rethinkdb-performance-data-1.png)

For insert performance, RethinkDB maintains a 10x improvement in throughput
over MyISAM, with an average of 24534.597 rows/sec up to 2,000,000 rows, while
InnoDB handles 8527.424 rows/sec, and MyISAM manages only 2483.277 rows/sec.
With more frequent measurements, we can see that InnoDB and MyISAM maintain
generally high throughput, but pause periodically for long stretches of time.
We believe that this is due to their B-tree structure, which need to expand
once in a while, a time-consuming operation that greatly undermines their
overall performance.

The threaded benchmark is a bit different:

![RethinkDB performance data.](/assets/images/posts/2009-08-12-rethinkdb-performance-data-2.png)

We've also benchmarked selects with no writers:

![RethinkDB performance data.](/assets/images/posts/2009-08-12-rethinkdb-performance-data-3.png)

RethinkDB's select performance is on par with MyISAM and InnoDB for threaded
and non-threaded benchmarks. The performance bottleneck for short selects is in
the network stack, and while we have plans to tackle this problem, we won't get
to it for a while. However, our algorithms significantly improve RethinkDB
performance on long selects and joins -- we will write a blog post soon with
more detailed results.

As always, comments and concerns are welcome, on our [blog][], [Twitter][], or
at [info@rethinkdb.com][].

[blog]: http://rethinkdb.com/blog/ 
[Twitter]: http://twitter.com/rethinkdb
[info@rethinkdb.com]: mailto:info@rethinkdb.com
