---
layout: post
title: "High scalability: SQL and computational complexity"
author: Slava Akhmechet
author_github: coffeemug
--- 

Recently there has been [a lot][1] [of][2] [discussion][3] on fundamental
scalability of traditional relational database systems. Many of the blog posts
on this topic give a great overview of some of the immediate issues faced by
engineers while scaling relational databases, but don't dissect the problem in
a systematic way and with sufficient depth to get to the core issues. I'd like
to dedicate a series of blog posts to the problem of scalability and how it
pertains to relational databases.
<!--more-->

[1]: http://www.yafla.com/dforbes/Getting_Real_about_NoSQL_and_the_SQL_Isnt_Scalable_Lie/
[2]: http://cacm.acm.org/blogs/blog-cacm/50678-the-nosql-discussion-has-nothing-to-do-with-sql/fulltext
[3]: http://blogs.computerworld.com/15510/the_end_of_sql_and_relational_databases_part_1_of_3


There are a number of aspects of an RDBMS that are relevant to high
scalability:

  * Relational data model
  * Constraint enforcement (including referential integrity)
  * SQL and its operational semantics
  * ACID compliance

In addition, every aspect above must be discussed in the context of the
following attributes:

  * A specific usage pattern
  * The implementation (a concrete system vs. a theoretically possible ideal)
  * Hardware platform (few expensive machines vs. many cheap machines)

In these series I will deal exclusively with OLTP (realtime) use cases. I will
not discuss various forms of analytics, data mining problems, etc. For this
post, let's define realtime as O(k * log N), where k is some small constant
that represents a well defined number of queries, and N is the total size of
the data (in rows). In other words, all operations of a realtime database must
completely evaluate in a logarithmic time relative to the full size of the
dataset, and the number of such operations required to make a logically
complete business transaction is small and independent of the size of the
dataset. I chose this definition because it seems intuitively interesting -
other functions that we see in practice are unlikely to satisfy realtime
demands of real world systems. In future blog posts I'll restrict this
definition even further to account for constant factors, but for now reasoning
in terms of complexity theory is sufficient.

There are two aspects of high scalability I'd like to cover - specific issues
and problems relevant today, and what we can expect from data management
systems in the future. In order to cover these aspects, I will focus both on
concrete systems commonly used in production and on theoretical ideals. For
completeness, I will also discuss most issues in terms of horizontal and
vertical scaling. Every time I talk about an RDBMS, I will define these
contexts explicitly.

Since I'm a big fan of theory of computation and programming language theory,
I'll kick off the series with a discussion on scalability of SQL from the
perspective of theory of computation (here I use the acronym 'SQL' in its
strictest sense and mean the actual query language as defined by the ANSI
standard and implemented by most vendors).

From a purely theoretical, computational perspective, the ANSI SQL-92 is
equivalent to a primitive recursive language. Most real world SQL
implementations are even more expressive, and are Turing-complete. As far as
vertical scalability is concerned, SQL is simply too expressive. Even if we
restrict ourselves to SQL-92, it is possible to write queries of polynomial, or
even exponential complexity - a far cry from a logarithmic requirement we
established earlier. This means that according to our definition of real-time,
SQL is fundamentally not a vertically scalable language.

What about horizontal scalability? Reasoning about it is more difficult because
it involves somewhat esoteric computational classes, and requires additional
assumptions. To simplify the reasoning, we make one key assumption.  We assume
that we can only have a polynomial number of machines (and cores) - this
appears to hold true because the number of machines we can manufacture is
dwarfed by the astronomical amounts of information we consume. If this holds
true, even if we can trivially parallelize each query, an exponential function
(the amount of information) divided by a polynomial (number of machines) still
dominates the logarithmic function we defined earlier as acceptable. This means
that given modern trends, if a given query isn't scalable vertically, it also
isn't scalable horizontally, which makes SQL fundamentally unscalable, period.

Of course so far we've shown what we already know - that it is possible to
write SQL queries that will likely never be fast enough to evaluate in
practice. At first glace this doesn't appear very useful - all we have to do is
avoid writing such queries and use the subset of SQL that can be evaluated in
logarithmic time. Unfortunately from a theoretical (and far too often
practical) perspective doing this is impossible.

The culprit is SQL's lack of operational semantics. Even a simple point query
can (and often does) run in O(1) time for hash indexes, O(log N) for tree
indexes, or O(N) for a linear scan. For more complicated queries, there are too
many edge cases where the optimizer might magically switch from logarithmic to
linear execution on a whim, despite having an index available.  In practice,
these changes result in expensive downtime, and hours of debugging and
rearchitecting. For massively scalable realtime systems, this is SQL's
Achilles' heel - you can't use a subset of SQL that runs in logarithmic time -
some of the time (in practice, far more often than you'd like), you'll end up
writing queries that don't satisfy your requirements. If we do settle on a
declarative query language (and I believe that anything else is a huge step
backward) for massively scalable systems, it must have the property that any
query you could express in this language is guaranteed to evaluate in
logarithmic time.

Of course such a language has a significantly limited purpose. It cannot be
used for most analytics problems, and more importantly for realtime systems,
cannot be used for realtime problems which involve polynomial islands of data
in the exponential universe. Facebook may some day have billions of users, but
any given user is unlikely to have more than a thousand friends. In this
scenario there are realtime subproblems where linear, and loglinear queries are
perfectly acceptable, and our language can't handle them. This means that for
these subproblems, one must use a different system, which may or may not be an
acceptable solution. Perhaps a better solution is to design a database system
that only allows to run provably logarithmic queries for massive datasets, but
relaxes the requirement for smaller subsets of data.

Unfortunately it would be extremely difficult to modify SQL to satisfy this
behavior because it isn't modular - almost all additions are special forms, and
it is so far removed from any theoretical model (including relational algebra),
that reasoning about it in a rigorous way is extremely difficult for both
humans and compilers. My prediction is that systems of the future will use a
modular, verifiable, higher order query language capable of enforcing various
complexity requirements at compile time, and that it will not look very much
like SQL.
