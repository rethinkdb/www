---
layout: post
title: "Building a realtime API with RethinkDB and Pushpin"
author: Justin Karneges
author_github: jkarneges
---
*Justin Karneges is the founder of [Fanout][]. This post originally appeared on
the [Fanout blog][].*

[Fanout]: https://fanout.io
[Fanout blog]: http://blog.fanout.io/2015/05/20/building-a-realtime-api-with-rethinkdb/

[RethinkDB][] is a modern NoSQL database that makes it easy to build realtime
web services. One of its standout features is called [Changefeeds][].
Applications can query tables for ongoing changes, and RethinkDB will push any
changes to applications as they happen. The Changefeeds feature is interesting
for many reasons:

[RethinkDB]: /
[Changefeeds]: /docs/changefeeds

- You don't need a separate message queue to wake up workers that operate on new data.
- Database writes made from anywhere will propagate out as changes. Use the
  RethinkDB dashboard to muck with data? Run a migration script? Listeners will
  hear about it.
- Filtering/squashing of change events within RethinkDB. In many cases it may
  be easier to filter events using ReQL than using a message queue and
  filtering workers.

This makes RethinkDB a compelling part of a realtime web service stack. In this
article, we'll describe how to use RethinkDB to implement a leaderboard API
with realtime updates. Emphasis on *API*. Unlike other leaderboard examples you
may have seen elsewhere, the focus here will be to create a clean API
definition and use RethinkDB as part of the implementation. If you're not sure
what it means for an API to have realtime capabilities, check out [this
guide][1].

[1]: http://blog.fanout.io/2015/04/02/realtime-api-design-guide/

<!--more-->

We'll use the following components to build the leaderboard API:

* Database: [RethinkDB][], hosted by [Compose][]
* Web service: [Django][], hosted by [Heroku][]
* Realtime push to clients: [Pushpin][], hosted by [Fanout][]

[RethinkDB]: /
[Compose]: https://www.compose.io/
[Django]: https://www.djangoproject.com/
[Heroku]: https://www.heroku.com/
[Pushpin]: http://pushpin.org/
[Fanout]: https://fanout.io/

Since the server app targets Heroku, we'll be using environment variables for
configuration and foreman for local testing.

Read on to see how it's done. You can also look at the [source][].

[source]: https://github.com/fanout/leaderboard

# Setup

To set up the environment locally, we install RethinkDB and Pushpin, and then
set some notable environment variables in our .env file:

```
DATABASE_URL=rethinkdb://localhost:28015/leaderboard
GRIP_URL=http://localhost:5561?key=changeme
```

The `DATABASE_URL` points to the local instance of RethinkDB, in a way that's
similar to how you'd use the variable to point to PostgreSQL. Heroku doesn't
natively support RethinkDB, but we reuse this environment variable and our
application includes its own code to parse it.

The `GRIP_URL` points to the control endpoint of Pushpin, used for publishing
data to listening clients. Pushpin's routes file contains a single line: `*
localhost:5000`, which instructs it to forward requests to an origin server
listening on port 5000, which is the default port used when running a Django
application with foreman. We can then make requests through Pushpin (port 7999)
to reach the Django application.

To set up the production environment in the cloud, follow these additional steps:

- Use Compose to create a RethinkDB cluster.
- Set up a domain in Fanout with the origin server set to the backend Heroku
  app. We're using a custom domain: api.leaderboardapp.org
- Configure DNS as necessary (e.g. we point leaderboardapp.org at Heroku and
  api.leaderboardapp.org at Fanout).
- Use an SSH tunnel between Heroku and Compose (see the [tunnel.py][] script,
  which Compose also [wrote][3] about), and set the related SSH environment
  variables.
- Set `DATABASE_URL` to point to the Compose tunnel.
- Set `GRIP_URL` to point to the Fanout API, e.g.:
  `https://api.fanout.io/realm/{realm-id}?iss={realm-id}&key=base64:{urlencoded
  key}`

[tunnel.py]: https://github.com/fanout/leaderboard/blob/master/tunnel.py
[3]: https://blog.compose.io/tunneling-from-heroku-to-compose-rethinkdb/

Notably, there is no difference in application code between the two
environments. Just the SSH tunnel and environment variables.

# API definition

The leaderboard API is fairly simple, with two main endpoints:

- GET `/boards/{board-id}/` - Return the top players (with scores) of a given
  board. If the request includes the header `Accept: text/event-stream`, then
  the response will be a Server-Sent Events stream of changes instead.
- POST `/boards/{board-id}/players/{player-id}/score-add/` - Increment the
  score of a player.

Server-Sent Events is a simple protocol for pushing data to clients using a
never-ending HTTP response. The event stream will contain events of type
`update`, where the data for each event is the board object (the same data
returned by a normal GET request). This way, clients that want to know the
current leaderboard state in realtime can use the event stream rather than
polling the board endpoint.

# Models

To make it easy to interact with the database, we'll create a couple of model
classes: `Board` and `Player`. These classes won't use the Django ORM, but
they'll be designed to behave similarly.

For example, here's how the classes could be used to create a new leaderboard
and add a player to it:

```python
from leaderboardapp.models import Board, Player

board = Board()
board.save()

player = Player(board=board, name='Alice')
player.save()
```

In order to make this work, we create a private convenience method
`_get_conn()`, which creates a RethinkDB `r` object and connects it to the
server based on the `DATABASE_URL`. It also supports pre-populating the
database on the first invocation, and is thread safe using `threading.local()`.
Each thread will get its own connection.

```python
import os
from urlparse import urlparse
import threading
import rethinkdb as r

_threadlocal = threading.local()

_url_parsed = urlparse(os.environ['DATABASE_URL'])
assert(_url_parsed.scheme == 'rethinkdb')
hostname = _url_parsed.hostname
port = _url_parsed.port
dbname = _url_parsed.path[1:]
del _url_parsed

def _ensure_db(conn):
    # create database
    try:
        r.db_create(dbname).run(conn)

        # ... set any db defaults here ...

    except r.RqlRuntimeError:
        # already created
        pass

def _get_conn():
    if not hasattr(_threadlocal, 'conn'):
        _threadlocal.conn = r.connect(hostname, port)
        _ensure_db(_threadlocal.conn)
    return _threadlocal.conn
```

With our handy `_get_conn()` method, we are able to write model classes like
this:

```python
class Player(object):
    def __init__(self, id=None, board=None, name=None, score=None):
        self.id = id
        self.board = board
        if name is not None:
            self.name = name
        else:
            self.name = ''
        if score is not None:
            self.score = score
        else:
            self.score = 0

    def save(self):
        if self.id:
            self.get_row().update({
                'name': self.name,
                'score': self.score,
            }).run(_get_conn())
        else:
            assert(self.board)
            ret = Player.get_table().insert({
                'name': self.name,
                'score': self.score,
                'board': self.board.id
            }).run(_get_conn())
            self.id = ret['generated_keys'][0]

    def delete(self):
        self.get_row().delete().run(_get_conn())

    def get_row(self):
        assert(self.id)
        return Player.get_table().get(self.id)

    def apply_rowdata(self, row):
        if not self.id:
            self.id = row['id']
        if self.board is None:
            self.board = Board(id=row['board'])
        self.name = row['name']
        self.score = row['score']

    @staticmethod
    def get_table():
        try:
            r.db(dbname).table_create('players').run(_get_conn())
        except r.RqlRuntimeError:
            # already created
            pass
        return r.db(dbname).table('players')

    @staticmethod
    def get(id):
        row = Player.get_table().get(id).run(_get_conn())
        if row is None:
            raise ObjectDoesNotExist()
        p = Player()
        p.apply_rowdata(row)
        return p
```

The above `Player` class encapsulates RethinkDB queries and exposes familiar
methods to the user such as `get()`, `save()`, and `delete()`.

For brevity, not all methods of the `Player` class are shown. See the
[source][4] for all available methods. Two notable methods to be aware of,
though, are `get_top_for_board()`, and `get_all_changes()`. Here's the relevant
code:

[4]: https://github.com/fanout/leaderboard/blob/master/leaderboardapp/models.py

```python
class Player(object):

    ...

    @staticmethod
    def get_top_for_board(board, limit=10):
        out = list()
        rows = Player.get_table().\
            order_by(r.desc('score')).\
            filter({'board': board.id}).\
            limit(limit).run(_get_conn())
        for row in rows:
            p = Player(board=board)
            p.apply_rowdata(row)
            out.append(p)
        return out

    ...

    @staticmethod
    def get_all_changes():
        return Player.get_table().changes().run(_get_conn())
```

The `get_top_for_board()` method returns the leading players of the board,
sorted by score. The `get_all_changes()` method returns an iterable that can be
used to read for new score changes. Reads will block until changes are made.
More on that later.

# Views

To assist with writing views, we declare some helper methods that handle
assembling `Board` and `Player` objects into JSON responses:

```python
def _board_data(board, players):
    return {'players': [_player_data(p) for p in players]}

def _board_json(board, players, pretty=True):
    if pretty:
        indent = 4
    else:
        indent = None
    return json.dumps(_board_data(board, players), indent=indent)

def _board_response(board, players):
    return HttpResponse(_board_json(board, players) + '\n',
        content_type='application/json')

def _player_data(player):
    return {
        'id': player.id,
        'name': player.name,
        'score': player.score
    }
```

Implementing the `/boards/{board-id}/` endpoint becomes straightforward:

```python
from django.http import HttpResponse, HttpResponseNotFound, \
    HttpResponseNotAllowed
from gripcontrol import HttpStreamFormat
from django_grip import set_hold_stream, publish
from .models import ObjectDoesNotExist, Board, Player

def board(request, board_id):
    if request.method == 'GET':
        try:
            board = Board.get(board_id)
        except ObjectDoesNotExist:
            return HttpResponseNotFound('Not Found\n')

        accept = request.META['HTTP_ACCEPT']
        if accept:
            accept = accept.split(',')[0].strip()
        if accept == 'text/event-stream':
            set_hold_stream(request, str(board_id))
            return HttpResponse(content_type='text/event-stream')
        else:
            players = Player.get_top_for_board(board, limit=5)
            return _board_response(board, players)
    else:
        return HttpResponseNotAllowed(['GET'])
```

If a normal GET request is made to the board endpoint, then the top 5 players
are returned within the object summarization. Easy enough! However, if the
client requests an event stream, then an HTTP streaming response is activated
through Pushpin. We'll discuss how that works in the next section.

# Realtime updates

Now we get to the fun realtime stuff!

For the view, we call `set_hold_stream()` on the request object if it should be
turned into a long-lived publish-subscribe stream:

```python
if accept == 'text/event-stream':
    set_hold_stream(request, str(board_id))
    return HttpResponse(content_type='text/event-stream')
```

The second argument to `set_hold_stream()` is the channel to subscribe the
request to. We'll use the board id for that. The django-grip middleware ensures
this information is passed to Pushpin when the `HttpResponse` is returned.

Note that the Django application does not hold the request open. It simply
responds immediately (and statelessly) to Pushpin with subscription
information, and it is Pushpin that actually holds the outer client request
open.

We also include a publishing method in views.py, to handle the sending of
realtime updates to listening clients:

```python
def publish_board(board):
    players = Player.get_top_for_board(board, limit=5)
    publish(str(board.id),
        HttpStreamFormat('event: update\ndata: %s\n\n' %
            _board_json(board, players, pretty=False)))
```

This `publish_board()` method gets the latest board state and publishes it out
using Server-Sent Events formatting.

Next, we glue this with the RethinkDB changefeed. We'll create a separate
worker module (dblistener.py) to listen for changes and publish updates. Here's
the complete code of the worker:

```python
import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE',
    'leaderboard.settings')
django.setup()

import time
import logging
from rethinkdb.errors import RqlDriverError
from leaderboardapp.models import Board, Player
from leaderboardapp.views import publish_board

logger = logging.getLogger('dblistener')

while True:
    try:
        for change in Player.get_all_changes():
            logger.debug('got change: %s' % change)
            try:
                row = change['new_val']
                board = Board.get(row['board'])
                publish_board(board)
            except Exception:
                logger.exception('failed to handle')
    except RqlDriverError:
        logger.exception('failed to connect')
        time.sleep(1)
```

This worker will run separately from the web service, to ensure that there is
only one instance running at a time. We declare it as "worker" in our Procfile.

The way the above code works is straightforward. It listens for player changes
from the database using `get_all_changes()`. We then publish the full board
state, using `publish_board()` from views.py. The while loop and try/except
ensure that if the database connection is ever lost, the worker will re-run the
query (which will cause a reconnect).

# Front end

Check out the leaderboard in action here! [leaderboardapp.org][]

[leaderboardapp.org]: http://leaderboardapp.org/


The front end is a simple [React][]-based website that uses the leaderboard API
underneath.

[React]: https://facebook.github.io/react/

# Conclusion

RethinkDB eases the development of realtime web services. Change notifications
can be received directly from the database itself, allowing centralized
management of updates. There's also no need to use a separate message queue to
propagate the updates to your edge tier.

Realtime API development doesn't get easier than this!
