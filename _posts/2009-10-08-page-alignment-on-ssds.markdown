---
layout: post
title: Page alignment on SSDs
tags:
- benchmarks
--- 

In our previous [post][] we discussed the optimal block-size for B-trees on
solid-state drives. A few people mentioned page alignment - an issue that can
cause serious performance hits on SSDs if unaccounted for. It's a complex
topic, and we will dedicate two posts to its discussion. In this post we'll
address alignment behavior while reading directly from the block device. In the
next post, we'll talk about partitioning the drive, and the effects of reading
from the filesystem instead of reading from the device directly.
<!--more-->

[post]: {% post_url 2009-10-05-rethinking-b-tree-block-sizes-on-ssds %}

For this test we ran [Rebench][] in random read mode, with block sizes ranging
from 512B to 4KB, with a 512B increment. We also set the stride parameter to
values ranging from 512B to 4KB, with a 512B increment. In the random read
mode, the stride parameter simply aligns random offsets to the boundary. This
lets us test how different combinations of block sizes and alignment values
affect performance. Here are the results for the 16GB SUPER TALENT MasterDrive
OCX (MLC):

[Rebench]: {% post_url 2009-10-02-rebench-cutting-through-the-myths-of-io-performance %}

![Page alignment on SSDs](/assets/images/posts/2009-10-08-page-alignment-on-ssds-1.png)

In one glance we can see from the mesh on top that performance spikes whenever
the alignment is a power of two. The heatmap shows that performance quickly
drops off for larger blocks, and that the best performing workload reads 512B
blocks from 4KB-aligned offsets. An open question remains: if we align our
blocks at 4KB boundaries and can read the first 512B chunk very quickly, how
can we read the rest of the chunks without performance loss? We know from
previous testing on our rotational drive that reading larger blocks did not
result in a performance drop-off, which means the problem isn't likely to be in
the kernel configuration or the data channel. Perhaps it's a problem with the
drive's firmware, or the driver, or perhaps it's an inherent limitation of the
drive. We'll be posting results on the Intel X-25M G2 MLC and X-25E SLC drives
soon; we're looking forward to comparing the results.

Stay tuned for information on how the block size and alignment behaves with
different partitioning and file system schemes. In the meantime, if you'd like
more precise information on how the drive behaves, here's a 2D visualization:

![Page alignment on SSDs](/assets/images/posts/2009-10-08-page-alignment-on-ssds-2.png)
