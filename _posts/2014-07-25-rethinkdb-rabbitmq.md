---
layout: post
title: "Feed RethinkDB changes directly into RabbitMQ"
author: Watts Martin
author_github: chipotle
---

RethinkDB's new [changefeeds][cf] let your applications subscribe to changes
made to a table in real-time. They're a perfect match with a distributed
message queue system like [RabbitMQ][rm]: changes can be sent from RethinkDB to
a RabbitMQ topic exchange with only a few extra lines of code. RabbitMQ then
queues them to pass on to any client subscribed to that exchange. If you need
to to send information about those changes to a large number of clients as
efficiently as possible, RabbitMQ is the rodent you need. Imagine a changefeed
for real-time stock updates being distributed to a thousand terminals on a
trading floor.
<!--more-->

[cf]: http://rethinkdb.com/docs/changefeeds
[rm]: http://www.rabbitmq.com

[@deontologician](https://github.com/deontologician) has written an integration
tutorial on using RethinkDB with RabbitMQ, and he's provided it for all three
of the languages we support: [JavaScript][1] (using [ampqlib][] for Node.js),
[Python][2] (using [pika][]), and [Ruby][3] (using [Bunny][]). Even if you're
not using one of those languages, the basic techniques in the article should
get you going.

[ampqlib]: http://www.squaremobius.net/amqp.node/
[pika]: http://pika.readthedocs.org/
[Bunny]: http://rubybunny.info/

Check it out: [Integrating RethinkDB with RabbitMQ][4]

[1]: http://rethinkdb.com/docs/rabbitmq/javascript/
[2]: http://rethinkdb.com/docs/rabbitmq/python/
[3]: http://rethinkdb.com/docs/rabbitmq/ruby/
[4]: http://rethinkdb.com/docs/rabbitmq/
