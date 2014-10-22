---
layout: post
title: "Rebench: cutting through the myths of I/O performance"
tags:
- benchmarks
--- 

A very wise systems programmer once told me: "Don't guess. Measure." Since
then, I've learned the hard way that guessing too much about performance is
death by a thousand cuts. For RethinkDB, dozens of factors for I/O alone
affect performance (not to mention memory, buses, caches, and CPU cores). In
order to design the fastest database on Earth, we constantly test the
following factors:

  * Performance of **read** and **write** operations.
  * Behavior for **random** and **sequential** workloads: 
    * For random workloads, the behavior of **uniform**, **normal**, and
      **power** distributions (with different distribution parameters).
    * For sequential workloads, the seek **direction** and various **strides**.
  * Performance changes for different **block sizes**.
  * Type of I/O calls (**pread**/**pwrite** vs. **read**/**write** vs.
  	**aio_read**/**aio_write** vs. **mmap**).
  * **Page cache** performance on different workloads compared to **direct
  	I/O**.
  * Different **flushing** strategies for write operations.
  * Splitting a given workload across **multiple threads**, and running
  	multiple different workloads **concurrently**: 
    * For concurrent workloads, different file descriptor **sharing**
      strategies.
  * **Space utilization** of the drive.
  * Different flags (**O_APPEND**, **O_NOATIME**, etc.)
  * Different **filesystems** and **mount flags**.
  * Performance differences across **drives**, **RAID controllers**, and
  	**operating systems**.

There are a number of existing tools designed to test I/O performance
(**hdparm**, **sysbench**, **IOBench**), but none of them gave us the high
precision control and number of options we needed. So we wrote our own -
**Rebench**. Rebench is designed to perform precision drilldown tests for
different I/O workloads, and combine workloads in order to give an idea of how
a system will behave in complex situations. We designed Rebench to be
flexible, so every one of the factors we measure can be mixed and matched.
With Rebench, if we wonder about a particular aspect of I/O performance, we
don't have to guess - it only takes a couple of seconds to come up with a test
that verifies our assumptions.

Here is the default run of Rebench (mode information removed for clarity).
/dev/sda is a Western Digital 80GB 7200RPM rotational drive:

    $ sudo rebench /dev/sda
    Benchmarking results for [/dev/sda] (74GB)
    Operations/sec: 87 (0.04 MB/sec)

We know that a random, uniform distribution workload with 512 byte block size
results in 87 I/O operations per second on our rotational drive. Let's try
sequential reads:
    
    $ sudo rebench -w seq /dev/sda
    Benchmarking results for [/dev/sda] (74GB)
    Operations/sec: 9778 (4.77 MB/sec)

The number of operations per second jumps up to nearly 10,000! What about our
solid-state drive? /dev/sdb is a 16GB SUPER TALENT MasterDrive OCX (MLC).

    $ sudo rebench -w seq /dev/sdb
    Benchmarking results for [/dev/sdb] (15GB)
    Operations/sec: 4682 (2.29 MB/sec)

So it doesn't perform as well as the rotational drive on sequential read
access. How about random reads?

    $ sudo rebench /dev/sdb
    Benchmarking results for [/dev/sdb] (15GB)
    Operations/sec: 4923 (2.40 MB/sec)

Ah! We blow the rotational drive out of the water at a factor of 50
improvement. And finally, how does the solid-state drive perform for random
writes?
    
    $ sudo rebench -o write /dev/sdb
    Benchmarking results for [/dev/sdb] (15GB)
    Operations/sec: 16 (0.01 MB/sec)

Not well, at only 16 random write operations per second! How about sequential
writes?

    
    $ sudo rebench -o write -w seq /dev/sdb
    Benchmarking results for [/dev/sdb] (15GB)
    Operations/sec: 6576 (3.21 MB/sec)

Basically the same as reads, which means the SSD translation layer for random
writes on this drive needs some work.

Finally, if you don't pass any flags to Rebench on the command line, it
accepts them on standard input and treats each line as a separate workload to
be run concurrently:

    $ sudo rebench
    /dev/sdb
    /dev/sda
    Benchmarking results for [/dev/sdb] (15GB)
    Operations/sec: 4636 (2.26 MB/sec)
    ---
    Benchmarking results for [/dev/sda] (74GB)
    Operations/sec: 85 (0.04 MB/sec)

Rebench is work in progress - we combined dozens of smaller programs we wrote
into a unified tool just a few days ago. There's some spaghetti code involved,
and probably some lurking bugs, but in the meantime it gets the job done. You
can get it at GitHub:

    git clone git://github.com/coffeemug/rebench.git

or download the source directly:
    
    http://github.com/coffeemug/rebench/tarball/master

To build Rebench, simply run `make`. You may need to install GNU Scientific
Library, if you don't have it already.

Rebench is released under the GPL license, so we welcome improvements, bug
fixes, and ports to other operating systems. Last but not least, we welcome
hardware donations. Happy benchmarking!

