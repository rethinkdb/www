---
layout: post
title: RethinkDB's first community client driver is for Haskell
tags:
- drivers
- haskell
--- 

Thanks to [Etienne Laurin](https://github.com/atnnn), there is now a **Haskell
client for RethinkDB**: check out the [release
announcement](http://permalink.gmane.org/gmane.comp.lang.haskell.cafe/101764)
on Haskell-Cafe.

The first version of the protocol definition is arcane and undocumented (a
[new spec
proposal](https://github.com/rethinkdb/rethinkdb/wiki/protobuf_rfc_raw_spec) is
in the works), so he took on the daunting task of reverse engineering [the
existing published drivers](http://www.rethinkdb.com/docs/guides/drivers/). Etienne
and is the first community member to release a RethinkDB community driver. 

There were quite a few RethinkDB team members that really wanted to implement this themselves, 
but Etienne was first-- and we're very grateful for his hard work. 
The [result looks great](http://hackage.haskell.org/package/rethinkdb):

```haskell
run h $ orderBy ["reduction"]
    . groupedMapReduce (! "Stname") mapF (0 :: NumberExpr) (R.+)
    . filter' filterF
    . pluck ["Stname", "POPESTIMATE2011", "Dem", "GOP"]
    . zip'
    $ eqJoin (table "county_stats") "Stname" (table "polls")
        where mapF doc = ((doc ! "POPESTIMATE2011") R.*
                        ((doc ! "GOP") R.- (doc ! "Dem"))) R./ (100 :: Int)
            filterF doc = let dem = doc ! "Dem" :: NumberExpr; gop =
doc ! "GOP" in (dem R.< gop) `and'` ((gop R.- dem) R.<
(15::Int))
```
The next step is to make this a monad!

An [improved protocol definition](https://github.com/rethinkdb/rethinkdb/wiki/protobuf_rfc_raw_spec) and 
accompanying documentation is upcoming, which we hope will make writing RethinkDB libraries in 
other languages easier. The question remains: which language will be next? Go? Clojure? Arc?
