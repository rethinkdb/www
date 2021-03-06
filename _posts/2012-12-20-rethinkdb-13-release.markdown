---
layout: post
title: RethinkDB 1.3 is out, now available on OS X
tags:
- announcements
--- 

We've released RethinkDB 1.3 ([Metropolis][yt]) which has a large number of
enhancements, and adds support for OS X and several other platforms. As of the
1.3 release, the server can now be installed on the following platforms:

[yt]: http://www.youtube.com/watch?v=ZSExdX0tds4

* OS X Lion and above (>= 10.7)
* 32-bit and 64-bit Ubuntu Lucid and above (>= 10.04)

Porting to OS X was one of the most requested features, and allows OS X users
to try RethinkDB without installing a Linux VM. The story of long and arduous
adventure of overcoming the many differences between the Darwin and Linux
kernels and their surrounding environments remains to be told by [@srh][].
<!--more-->

[@srh]: https://github.com/srh

The 1.3 release involved closing [sixty-nine issues][1] over five weeks,
including twenty-five bug fixes, ten enhancements, and thirty-four general
improvements. A number of community projects based on RethinkDB have started in
the past month, so we're kicking off a [community projects wiki][2] with
various contributions from community members including C, Haskell, and Go
client drivers, example code, and portability recipes.

[1]: https://github.com/rethinkdb/rethinkdb/issues?labels=&milestone=4&page=1&state=closed
[2]: https://github.com/rethinkdb/rethinkdb/wiki/Community-contributions

[Download][] the latest release, and check back soon for more cool stuff!

[Download]: /docs/install

