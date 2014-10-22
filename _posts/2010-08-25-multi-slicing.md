---
layout: post
title: Multi Slicing
tags:
- announcements
--- 

The basic data structure that powers databases is called a B-tree. This is
where you actually store the user's data. B-trees are great because you can
put huge amounts of data in them and access remains fast. In fact, the naive
strategy of putting a whole data set into one B-Tree doesn't break down
because of access time. It does, however, break down when you try to support a
multiaccess paradigm.

Six years ago, multiaccess was nice. Now that processors have multiple cores,
it's crucial. Four cores fighting over one B-tree means a lot of wasted
processor time. In a multiaccess scheme, different cores can concurrently
access data. This gets tricky. You can go looking for a piece of data only to
find that someone has moved it since you started; that's trouble: for all you
know it was deleted. You could start the search over, but without guarantees--
maybe you'll get unlucky and it will be plucked out from under you again. How
do you know when to give up? Your database is now blazingly fast, but also
broken. We handle this with a locking scheme.

With a locking scheme, you gain the ability to say: "Okay, I'm going to go
look for this piece of data, no one else is allowed to touch it." If someone
else wants to get at that piece of data before you're done--they have to wait.
The database is fixed, but it's not quite as blazingly fast as it used to be.
The problem is that sometimes cores have to wait for data, and while they wait
they're just twiddling their thumbs. There isn't a good way to prevent these
waits, but we can put that time toward something productive.

The problem isn't the waiting, it's the lack of things to do during that time.
The solution is to slice up our B-Tree into several smaller B-Trees. Every
possible key has one and only one slice that it can ever be stored in. We do
this with hashing.

Now even if a core locks up an entire B-Tree, you can still do work in the
intervening time. Now that we support multiple slices, the question is: how
many slices do we actually want? There are downsides to both extremes: too
many slices and the efficiency of the B-Tree structure is underused, too few
and CPUs are underused. At RethinkDB we've found experimentally that 4 is a
sufficiently high value. The quick back-of-the-envelope calculation is that an
unsliced B-Tree will defy computation about $latex 2 \%$ of the time. That
translates to an hour of wasted CPU time every 2 days. This waste falls off
very sharply with our innovation: 2 slices are busy: $latex .02^2 = 0.0004$
(just $latex .04 \% $ of the time) and 4 slices are busy $latex .02^4 =
0.00000016$ or $latex 0.000016 \% $. At which point it will take you 700 years
to waste an hour of CPU time. That's a number we can live with.

