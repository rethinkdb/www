---
layout: post
title: RethinkDB is out - an open-source distributed database
tags:
- announcements
--- 

There are [many](http://www.mongodb.org/)
[exciting](http://basho.com/) [database](http://couchdb.apache.org/)
products that make developing scalable applications much, much
friendlier and easier. After three years of work, our humble
contribution to the field is out. RethinkDB is built to store JSON
documents, and scale to multiple machines with very little effort. It
has a pleasant query language that supports really useful queries like
table joins and group by, and is easy to setup and learn.

Here's a quick feature list of RethinkDB 1.2 (<a
href="http://www.youtube.com/watch?v=K-IpHfQRhkg"
class="hidden">Rashomon</a>):

* __Simple programming model__
  * JSON data model and immediate consistency
  * Distributed joins, subqueries, aggregation, atomic updates
  * Hadoop-style map/reduce
* __Easy administration__
  * Friendly web and command-line administration tools
  * Takes care of machine failures and network interrupts
  * Multi-datacenter replication and failover
* __Horizontal scalability__
  * Sharding and replication to multiple nodes
  * Queries are automatically parallelized and distributed
  * Lock-free operation via MVCC concurrency

[Check it out](/) and tell us what you think!
