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

We’ll answer these questions by using different workloads from the YCSB benchmark. [You can learn more about YCSB here][ycsb], and review the [source code here][ycsb-fork]. An additional test investigates scalability for analytical workloads.

<!--more-->

In the results, we’ll see how RethinkDB 2.1.5 can be scaled to perform 1.3 million individual reads per second. We will also demonstrate well above 100 thousand transactions per second in a mixed 50:50 read/write workload - while at the full level of durability and data integrity guarantees. All benchmarks are performed across a range of cluster sizes, scaling up to 16 servers.

## A quick overview of the results

Getting right down to the details, we found that in a mixed read/write workload RethinkDB with two servers was able to perform nearly 16K queries per second (QPS) and scaled to almost 120K QPS while in a 16 server cluster. Under a “read only” workload and synchronous read settings, RethinkDB was able to scale from about 150,000 QPS up to over 550K QPS. Under the same workload, in an asynchronous “outdated read” setting RethinkDB went from 150K QPS on one server to 1.3M in a 16 server cluster.

Finally, we used a map-reduce query to compute word counts across the whole data set. This test evaluates RethinkDB's scalability for analytical workloads.

Here we we show how RethinkDB scales up to 16 servers with these workloads.

![Workload A][w-a]
![Workload C Synchronous][w-c-sync]
![Workload C Asynchronous][w-c-async]
![Analytical][analytical]

In the full report you can find the specifics of the tests and learn more about latency distributions as we scaled up to 16 server clusters for each workload.

### [Click here to view the full report][perf-report]

[analytical]: /assets/images/posts/2016-03-15-analytical.png
[perf-report]: https://docs.google.com/document/d/15vPsdB8YyynQYcmvWlb_MTjBb1lDY_Z6eeIl7T_NZx0/edit?usp=sharing
[w-a]: /assets/images/posts/2016-03-15-w-a.png
[w-c-async]: /assets/images/posts/2016-03-15-w-c-async.png
[w-c-sync]: /assets/images/posts/2016-03-15-w-c-sync.png
[ycsb-fork]: https://github.com/rethinkdb/ycsb
[ycsb]: https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark
