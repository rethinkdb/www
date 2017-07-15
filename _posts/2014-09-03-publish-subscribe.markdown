---
layout: post
title: "Publish and subscribe entirely in RethinkDB"
author: Watts Martin
author_github: chipotle
---

With RethinkDB's changefeeds, it's easy to create a publish-subscribe message
exchange without going through a third-party queue. [Josh Kuhn] has written a
small library, [repubsub][], that shows you how to build topic
exchanges&mdash;and he's written it in all three of our officially-supported
languages. He's put together a terrific [tutorial][] article demonstrating how
to use it. You can simply create a topic and publish messages to it:

[Josh Kuhn]: https://github.com/deontologician)
[repubsub]: https://github.com/rethinkdb/example-pubsub
[tutorial]: http://www.rethinkdb.com/docs/publish-subscribe/

```py
topic = exchange.topic('fights.superheroes.batman')
topic.publish({'opponent': 'Joker', 'victory': True})
```

Then subscribe to just the messages that match your interest.

```py
filter_func = lambda topic: topic.match(r'fights\.superheroes.*')
queue = exchange.queue(filter_func)
for topic, payload in queue.subscription:
    print topic, payload
```

Josh describes how to implement tags, nested topics and more, so check out the
[publish-subscribe tutorial][tutorial].
