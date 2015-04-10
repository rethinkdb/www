---
layout: document
title: Thanks for becoming a RethinkDB Contributor
active: community
permalink: community/cla/thanks/
---

# Thanks for becoming a RethinkDB contributor!

```javascript
r.db('rethink').table('contributors')
   .update({ 'count': r.row('count').add(1) })
```

We're looking forward to your [pull requests][1] on GitHub! Check out the
[community page][2] to get started with contributing.

[1]: https://github.com/rethinkdb/rethinkdb
[2]: /community
