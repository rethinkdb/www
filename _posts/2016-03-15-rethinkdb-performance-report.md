---
layout: post
title: "Performance & Scaling of RethinkDB"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image:
---

We get asked a lot of:
* "What sort of performance can I expect from a RethinkDB cluster?"
* "Does RethinkDB (web)scale?"
* "Can I use the outdated read mode to improve throughput in read-heavy workloads?"

We’ll attempt to answer these questions by using a couple different workloads from the YCSB benchmark. An additional test investigates scalability for analytical workloads.

<!--more-->

In the results, we’ll see how RethinkDB 2.1.5 can be scaled to perform 1.3 million individual reads per second. We will also demonstrate well above 100 thousand transactions per second in a mixed 50:50 read/write workload - while at the full level of durability and data integrity guarantees. All benchmarks are performed across a range of cluster sizes, scaling up to 16 servers.
Throughout the development of RethinkDB we thought it wise to use a well known testing framework in which to measure RethinkDB performance. Yahoo has created a testing framework for analyzing the performance of databases and released it to the public. [You can learn more about YCSB here][ycsb], and review the [original source code here][ycsb-original].

We ported YCSB to be used with our official Java driver and intend to submit a pull request for it in the near future. [Our fork of YCSB is available for review here.][ycsb-fork]

## A quick overview of the results

Getting right down to the details, we found that in a mixed read/write workload RethinkDB with two clusters was able to perform nearly 16K queries per second (QPS) and scaled to almost 120K QPS while in a 16 node cluster. Under a “read only” workload and synchronous read settings, RethinkDB was able to scale from about 150,000 QPS up to over 550K QPS. Under the same workload, in an asynchronous “stale read” setting RethinkDB went from 150K QPS on one node to 1.3M in a 16 node cluster. Here we we show how RethinkDB scales up to 16 nodes with these various workloads.

![Workload A][w-a]
![Workload C Synchronous][w-c-sync]
![Workload C Asynchronous][w-c-async]
![Analytical][analytical]

In the full report you can find the specifics of the tests and learn more about latency distributions as we scaled up to 16 node clusters for each workload.

### [Click here to view the full report][perf-report]

[analytical]: /assets/images/posts/2016-03-15-analytical.png
[perf-report]: https://docs.google.com/document/d/15vPsdB8YyynQYcmvWlb_MTjBb1lDY_Z6eeIl7T_NZx0/edit?usp=sharing
[w-a]: /assets/images/posts/2016-03-15-w-a.png
[w-c-async]: /assets/images/posts/2016-03-15-w-c-async.png
[w-c-sync]: /assets/images/posts/2016-03-15-w-c-sync.png
[ycsb-fork]: https://github.com/rethinkdb/ycsb
[ycsb-original]: https://github.com/brianfrankcooper/YCSB
[ycsb]: https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark
