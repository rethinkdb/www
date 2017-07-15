---
layout: post
title: RethinkDB is switching over to Lisp
--- 

**April Fools! We aren't switching to Lisp (as much as we love the language).
We couldn't resist having a bit of fun.**

Over the past few months we've had many architectural discussions about the
future of database technology. It quickly became apparent to us that C++, the
language we used to develop RethinkDB, is not sufficiently expressive to build
the next-generation database product. We realized that in order to design the
database system of the future, we need to use a programming language of the
future as well.
<!--more-->

We did a quick survey of programming languages and eventually narrowed down our
choices to Erlang, Haskell, and Common Lisp. Two years ago, Damien Katz of
CouchDB laid out the [reasons][] why Erlang is a poor choice for database
products. Many of his arguments resonated with us, and we made a wise decision
not to repeat Damien's mistakes. When we dropped Erlang from consideration, we
were left with an impossible choice - Haskell vs. Lisp.

[reasons]: http://damienkatz.net/2008/04/couchdb_language_change.html

After many heated debates, I remembered a phrase drilled into to me by an ex-
coworker I deeply respect. He always said: "Don't guess. Measure." We decided
to take a measured approach and use data and logical reasoning instead of
emotional arguments. Because of the immense expressive power of both
programming languages, we could develop two prototypes in a matter of days, and
measure the performance with our internal benchmarking toolkit. Mike rewrote
RethinkDB in Haskell, and I rewrote it in Common Lisp. After running both
prototypes through our standard benchmarks, it immediately became clear that
the Lisp version easily beat the Haskell version by every metric we could
fathom. And so, we settled on Common Lisp.

One of the major criticisms of RethinkDB has been the closed nature of the
project. Fortunately, this is no longer a problem. The fact is, there are very
few developers that understand Common Lisp, so we no longer need to worry about
competing companies forking our source code. As we're preparing to open source
our Lisp code base, I'm happy to kick off the effort by listing the last few
lines of the source code in this post:

```
))))))))
)))))))))))))))))))))))))))))
)))))))))))
)))
)
```

