---
layout: post
title: 'RethinkDB challenge: find a bug, get a job'
tags:
- announcements
--- 

# The challenge

Follow the [installation instructions](/docs/install/) to set up the
server. Then, in a language of your choice, write an automated fuzzer
that sends randomized traffic to the database server with the purpose
of discovering a crash. The fuzzer can use `rethinkdb admin` to
reshard or replicate the database, one or more rethinkdb clients to
send randomized queries, direct TCP access to send faulty traffic to
the server, or a combination of approaches. We will consider all
candidates whose fuzzer manages to expose a server crash.

# The job

- Make the tests better. We'll give you an EC2 budget large enough to
  build something cool. You'll develop continuous integration
  tools with ability to spin up new machines to quickly test
  a branch with one command, and anything else awesome that you can
  dream up.
- Write good benchmarks and presentation tools. We want to run a
  single command that tells us whether we made RethinkDB faster or
  slower and generates useful graphs that we can put on the website.
- Come up with clever ways to test arcane code paths.  A sage affects
  ten thousand things without looking at ten thousand things.
- You'll get to work on a technically sophisticated product with smart
  people, and have the freedom to build awesome software.

# About you

- You love and understand Unix tools (Bash, at least some C, and at
  least one modern scripting language, preferably Python).
- You can't stand letting manual processes go un-automated.
- You get very, very nervous when you see untested code paths.
- You're extremely pragmatic. `shipping > bikeshedding`.
- You must be willing to relocate to the SF Bay Are (or already
  here!). We're located in Mountain View, CA, and currently cannot
  accept telecommuters.

# Getting started

You're welcome to drop by and ask for help on how to use the server as
you're writing the fuzzer. Go to [rethinkdb.com/community](/community)
and get in touch via IRC or google groups.

# Submission

Create a publicly accessible GitHub project that contains the source
code of the fuzzer and the instructions on how to run it. Then, create
a GitHub issue with information on the crash exposed by the fuzzer on
[https://github.com/rethinkdb/rethinkdb/issues](https://github.com/rethinkdb/rethinkdb/issues). In
the issue, specify that it's submitted in response to this challenge
and link to the fuzzer's GitHub url. Make sure to include contact
information in your GitHub profile.
