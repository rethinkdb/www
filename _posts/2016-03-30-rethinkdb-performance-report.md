---
layout: post
title: "Performance & Scaling of RethinkDB"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image:
---

We are happy to present our first published RethinkDB performance report to the world. After an internal collaborative effort we can reveal what we’ve discovered about the performance of RethinkDB. Some of the questions you might be looking to address may include:

* "What sort of performance can I expect from a RethinkDB cluster?"
* "Does RethinkDB scale?"
* "Can I use the outdated read mode to improve throughput in read-heavy workloads?"

We’ll answer these questions by using different workloads from the YCSB benchmark. [You can learn more about YCSB here][ycsb], and review the [source code here][ycsb-fork]. An additional test investigates scalability for analytical workloads.

<!--more-->

In the results, we’ll see how RethinkDB 2.1.5 scales to perform 1.3 million individual reads per second. We will also
demonstrate well above 100 thousand operations per second in a mixed 50:50 read/write workload - while at the full
level of durability and data integrity guarantees. We performed all benchmarks across a range of cluster sizes, scaling
up to 16 servers.


# A quick overview of the results

We found that in a mixed read/write workload RethinkDB with two servers was able to perform nearly 16K queries per second (QPS) and scaled to almost 120K QPS while in a 16 server cluster. Under a read only workload and synchronous read settings, RethinkDB was able to scale from about 150,000 QPS on a single node up to over 550K QPS on 16 nodes. Under the same workload, in an asynchronous “outdated read” setting, RethinkDB went from 150K QPS on one server to 1.3M in a 16 node cluster.

Finally, we used a MapReduce query to compute word counts across the whole data set. This test evaluates RethinkDB's scalability for analytical workloads in a simplistic but very common fashion. These types of workloads involve doing information processing on the server itself versus typical single or ranged reads and writes of information processed at the application level.

Here we we show how RethinkDB scales up to 16 servers with these various workloads:

![Workload A][w-a]
![Workload C Synchronous][w-c-sync]
![Workload C Asynchronous][w-c-async]
![Analytical][analytical]

In the full report you can find the specifics of the tests and learn more about latency distributions as we scaled up to 16 server clusters for each workload.

## [Click here to view the full report][perf-report]

# Notes

* We were fortunate enough to receive free credits from Rackspace to perform the majority of these tests and are very grateful for their contributions to open source software. All of [Rackspace’s OnMetal offerings can be found here][rackspace].
* We have published all relevant performance testing code and final results in the [rethinkdb/preformance-reports repository on Github][perf-reports-repo]
* We’d love to answer any questions you have about these tests. Come join us at [http://slack.rethinkdb.com][slack] and feel free to ask more specific questions we don’t answer here by pinging @danielmewes or @dalanmiller.
* Recently, the team behind BigchainDB - a scalable blockchain database built on top of RethinkDB - has benchmarked RethinkDB on a 32-server cluster running on Amazon's EC2. They measured throughputs of  more than a million writes per second. Their conclusion: "There is linear scaling in write performance with the number of nodes". The full report is available at [https://www.bigchaindb.com/whitepaper/][bigchaindb]


[analytical]: /assets/images/posts/2016-03-15-analytical.png
[bigchaindb]: https://www.bigchaindb.com/whitepaper/
[perf-report]: https://rethinkdb.com/docs/performance-reports/2-1-5-performance-report/
[perf-reports-repo]: https://github.com/rethinkdb/performance-reports
[rackspace]: https://www.rackspace.com/cloud/servers/onmetal
[slack]: http://slack.rethinkdb.com
[w-a]: /assets/images/posts/2016-03-15-w-a.png
[w-c-async]: /assets/images/posts/2016-03-15-w-c-async.png
[w-c-sync]: /assets/images/posts/2016-03-15-w-c-sync.png
[ycsb-fork]: https://github.com/rethinkdb/ycsb
[ycsb]: https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark
