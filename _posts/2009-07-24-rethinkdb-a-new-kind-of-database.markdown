---
layout: post
title: "RethinkDB: a new kind of database"
tags:
- announcements
author: Slavabot Akhmechet
author_github: coffeemug
--- 

Today, we're ready to announce [RethinkDB][] -- a new kind of database. It's
been a winding road. For two years, Mike, Leif, and I have been thinking
independently on how to bring a breath of fresh air to the database world.
Three months ago, we came together to form a company and bring our ideas to
reality. In these three months, we've raised seed funding from [Y
Combinator][], moved to California, and built a MySQL plugin that implements
the core of our vision -- a storage engine redesigned for the modern world.
With the exception of storage technology, database design has always been
beautiful. Now, with dropping costs of storage, the advent of solid state
drives, and advances in functional data structures theory, we can finally
replace that last messy component of database management systems with an
elegant, beautiful solution.
<!--more-->

[RethinkDB]: http://www.rethinkdb.com
[Y Combinator]: http://www.ycombinator.com

Much work remains to be done. RethinkDB isn't ready for general production use.
So, why release it today? At a recent Y Combinator dinner, Reid Hoffman (the
founder of LinkedIn) said: "If you're not embarrassed by the first version of
your product, you've launched too late." We're launching too late.  The article
you're reading now is served by a WordPress installation running live on
RethinkDB. Many of our internal benchmarks outperform a stock MySQL setup.
We're no longer terrified of data corruption (though we still keep our fingers
crossed). We're using RethinkDB for painless hot backups. The time is long
overdue for us to share our work with you.

We are committed to building an open, socially responsible company. In the
coming weeks we will be releasing as much information about the RethinkDB
internals as possible without compromising its commercial success. In the
meantime, we'd like to welcome your [feedback][].

[feedback]: mailto:info@rethinkdb.com

