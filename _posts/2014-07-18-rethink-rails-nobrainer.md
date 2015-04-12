---
layout: post
title: "Rethink and Rails together? A NoBrainer!"
author: Watts Martin
author_github: chipotle
---

Have you been looking for a tutorial on using RethinkDB with Ruby on Rails?
RethinkDB's Josh Kuhn ([@deontologician][@d]) has contributed a new integration
article for our documentation on using [NoBrainer][nb], a RethinkDB ORM that's
close to a drop-in replacement for ActiveRecord.

[@d]: https://github.com/deontologician
[nb]: http://nobrainer.io/

If you already have a little experience with Rails, NoBrainer will feel
familiar and natural to you already. You get model generation, scaffolding,
validation, and `belongs_to` and `has_many` associations. And, you get a
lightweight wrapper around ReQL that lets you execute queries like this:

```rb
# Find a comment from a user with 'bob' in its name sorted by the name.
# Note: NoBrainer will use the :name index from User by default
User.where(:name => /bob/).order_by(:name => :desc).to_a
```

Go read the full guide: [Using RethinkDB with Ruby on Rails][guide]

[guide]: /docs/rails
