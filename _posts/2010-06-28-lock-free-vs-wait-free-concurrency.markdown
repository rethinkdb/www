---
layout: post
title: Lock-free vs. wait-free concurrency
--- 

There are two types of [non-blocking thread synchronization][1] algorithms -
lock-free, and wait-free. Their meaning is often confused. In lock-free
systems, while any particular computation may be blocked for some period of
time, all CPUs are able to continue performing other computations.  To put it
differently, while a given thread might be blocked by other threads in a
lock-free system, all CPUs can continue doing other useful work without stalls.
Lock-free algorithms increase the overall throughput of a system by
occassionally increasing the latency of a particular transaction. Most high-
end database systems are based on lock-free algorithms, to varying degrees.

[1]: http://en.wikipedia.org/wiki/Non-blocking_synchronization

By contrast, wait-free algorithms ensure that in addition to all CPUs
continuing to do useful work, no computation can ever be blocked by another
computation. Wait-free algorithms have stronger guarantees than lock-free
algorithms, and ensure a high thorughput without sacrificing latency of a
particular transaction. They're also much harder to implement, test, and debug.
The [lockless page cache][2] patches to the Linux kernel are an example of a
wait-free system.
<!--more-->

[2]: http://lwn.net/Articles/291826/

In a situation where a system handles dozens of concurrent transactions and has
[soft latency requirements][3], lock-free systems are a good compromise between
development complexity and high concurrency requirements. A database server for
a website is a good candidate for a lock-free design.  While any given
transaction might block, there are always more transactions to process in the
meantime, so the CPUs will never stay idle. The challenge is to build a
transaction scheduler that maintains a good mean latency, and a well bounded
standard deviation.

[3]: http://en.wikipedia.org/wiki/Real-time_computing#Hard_and_soft_real-time_systems

In a scenario where a system has roughly as many concurrent transactions as CPU
cores, or has hard real-time requirements, the developers need to spend the
extra time to build wait-free systems. In these cases blocking a single
transaction isn't acceptable - either because there are no other transactions
for the CPUs to handle, minimizing the throughput, or a given transaction needs
to complete with a well defined non-probabilistic time period. Nuclear reactor
control software is a good candidate for wait-free systems.

RethinkDB is a lock-free system. On a machine with N CPU cores, under most
common workloads, we can gurantee that no core will stay idle and no IO
pipeline capacity is wasted as long as there are roughly N * 4 concurrent
transactions. For example, on an eight core system, no piece of hardware will
sit idle if RethinkDB is handling roughly 32 concurrent transactions or more.
If there are fewer than 32 transactions, you've likely overpaid for some of the
cores. (Of course if you only have 32 concurrent transactions, you don't need
an eight-core machine).
