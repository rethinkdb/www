---
layout: post
title: Will the real programmers please stand up?
--- 

We've been actively recruiting for four months now, and if there is one thing
we've learned, it's that Jeff Atwood wasn't kidding about [FizzBuzz][].

[FizzBuzz]: http://www.codinghorror.com/blog/2007/02/why-cant-programmers-program.html

Among our friends in the startup community, RethinkDB has the rep for having
the toughest interview process on the block. And it's true - the interview
process is something we won't compromise on. We're prepared to turn away as
many people as it takes to build a superb development team. We wrote that much
in an earlier [post][]. In the past few months we ran into people that thought
we have ridiculously high standards and are hiring rocket scientists who also
double majored in quantum mechanics and computer science. We don't. We just
won't hire programmers that can't code.
<!--more-->

[post]: {% post_url 2010-06-29-will-the-real-programmers-please-stand-up %}

In the interest of openness, we'll post the smoke test that makes us turn away
19 out of 20 candidates within half an hour of a phone conversation (and that's
_after_ screening the resumes). We don't ask people to code a solution to a
complex algorithms problem. We don't ask to solve tricky puzzle questions. We
don't ask to do complex pointer arithmetic or manipulation. Here is the
question that the vast majority of candidates are unable to successfully solve,
even in half an hour, even with a lot of nudging in the right direction:

```
Write a C function that reverses a singly-linked list.
```

That's it. We've turned away people with incredibly impressive resumes
(including kernel developers, compiler designers, and many a Ph.D. candidate)
because they were unable to code a solution to this problem in any reasonable
amount of time.

We ask other questions, of course. _What's the worst case complexity of
inserting N elements into a vector (or an ArrayList, or whatever your language
of choice calls dynamic arrays)?_ We don't care if you know, we just want you
to try and figure it out. We'll explain how a vector works internally. Hell,
we'll even accept O(N log N) as an answer.

_How would you implement a read-write lock?_ You don't actually have to code it
over the phone. Mentioning starvation issues is bonus points. For heaven's
sakes, just give us _something_. We try to ask about the difference between
cooperative and preemptive multitasking.

We try to ask about condition variables. 19 out of 20 times there is silence on
the other end.

Why do we ask these specific questions? Because they're part of a core body of
knowledge taught in any undergraduate curriculum worth its salt, and because in
some form or another, they came up in our daily work. And in four months we
found out that if you understand the difference between threads and coroutines,
can reverse a linked list, and have a basic understanding of condition
variables, chances are you're probably a much better programmer than most who
are looking for a job, and a huge chunk of those who aren't looking as well.

We're hiring people who can do more than what I listed above, but I don't think
we're asking for _too_ much more. Just a solid understanding of the
fundamentals, the drive to accomplish great things, and a little genuine love
for your craft. To quote one of my colleagues who heard about FizzBuzz for the
first time, "If they can't do FizzBuzz, what _can_ they do?". After spending
hours reviewing resumes, it takes twenty interviews to get to the candidate
that can pass the smoke tests. At an average of 45 minutes per interview, this
works out to fifteen hours of work. That's a lot of time to find one candidate
with a basic understanding of software engineering.

Will the real programmers please stand up?
