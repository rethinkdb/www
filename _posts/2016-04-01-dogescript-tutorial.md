---
layout: post
title: "Build realtime web apps with RethinkDB and Dogescript"
author: Skyla
author_github: skyla
---

I'm Skyla, RethinkDB's canine-in-residence. My vitally important
responsibilities at the office include terrorizing the UPS delivery man, gazing
intently at the team while they eat lunch, relentlessly gnawing stuffed
animals, and pursuing the insidious red dot. I've recently taken up computer
programming so that I can help the team build RethinkDB demos. In this
tutorial, I will demonstrate how to build a realtime web application with
RethinkDB and [Dogescript][].

Dogescript is a dynamic programming language designed to reflect the unique
canine patois popularly associated with doges. The language transpiles to
JavaScript, which means that users can take advantage of a large ecosystem of
existing libraries and frameworks. You can adopt Dogescript today without
giving up indispensable packages like [left-pad][].

My full-stack Dogescript demo uses Node.js on the backend. The frontend is
built with the handlebars templating library and jQuery. The application, which
is called Dogechat, displays a chat room with realtime messaging. It helpfully
displays each message as a doge meme.

<!--more-->

<img src="/assets/images/posts/2016-04-01-dogescreen.png">

# Such syntax

The Dogescript syntax is easy to read, replacing much of JavaScript's arbitrary
punctuation with clear and intuitive keywords. For example, you iterate over an
array with the `much` keyword, invoke functions with `plz`, and define
variables with `very`. A full introduction to Dogescript syntax is beyond the
scope of this tutorial, but you can find a [language reference][lang-ref] in
the project's [GitHub repository][repo].

My application's Node.js backend uses the [RethinkDBDash][] client library to
connect to the database. The following code example shows how to connect to the
database and perform a query, displaying the results to the console:

```javascript
so rethinkdbdash
very r is plz rethinkdbdash

plz r.table with 'dogechat'&
dose filter with {name:'Skyla'}&
dose then with much output
  plz console.loge with output
wow&
```

The query performs a `filter` operation on the `dogechat` table, looking for
all of the messages sent by me. In Dogescript, the `dose` keyword allows
chaining expressions. You can see the `then` method chained to the end of the
query, with an anonymous function to execute when the query completes.

# Much realtime

Let's paws for a moment and discuss how my Dogechat demo uses RethinkDB
changefeeds to propagate realtime updates. Changefeeds let you subscribe to a
query, triggering a callback every time there's new output. Instead of polling,
you get a live stream of updates as your data changes. In my application, I
attach a changefeed to the `dogechat` table and then broadcast new messages
over [socket.io][].

Changefeeds make it very easy to build scalable realtime applications. When you
horizontally scale your application, every instance can setup a changefeed and
get push updates from the database to relay to their connected frontend
clients. You don't have to rely on a message queue or other infrastructure to
propagate the updates.

Humans think that they are super clever, but none of this is really new. If
you've ever heard of the [Twilight Bark][], you know that dogs basically
invented distributed messaging systems.

The following code example shows how I attach a changefeed to a table,
broadcasting received updates over socket.io. It also has some boilerplate to
initialize the database table, creating it if it doesn't already exist:

```javascript
very makeTable is plz r.tableCreate with 'dogechat'
plz r.tableList&
dose contains with 'dogechat'&
dose not&
dose and with makeTable&
dose then with much
  very query is plz r.table with 'dogechat'&
  dose changes
wow& query
dose then with much feed 
  plz feed.each with much err change
    plz io.sockets.emit with 'message' change.new_val
  wow&
wow&
```

On the frontend, my application uses the socket.io client library to handle
incoming messages. When the frontend receives an incoming message, it uses a
handlebars template to render it as HTML that jQuery can append to the page.

```javascript
very template is plz Handlebars.compile with $("#template").html()

plz io&
dose on with 'message' addMessage

such addMessage much message
  very content is plz template with message
  plz $("#messages").append with content
wow
```

Like most web developers, I like to use third-party cloud services to support
key functionality that I'm too lazy to implement myself. For this demo
application, I decided to rely on [dogr.io][], a cloud platform that provides
doge memes as a service. In my handlebars template, I simply reference a
dogr.io address to obtain a doge meme image for each message:

```html
<script id="message-template" type="text/x-handlebars-template">
  <div class="message">
    <div class="user">{{name}}:</div>
    <div class="message">
      <img src="http://dogr.io/{{message}}.png?split=false"
    </div>
  </div>
</script>
```

# Fetch amaze

I used [Express][] to create a POST endpoint in my backend for sending
messages. The request handler performs a query, inserting a new document in the
database for each sent message:

```javascript
plz app.post with '/api/send' much req res
  very doc is {name:req.body.name,message:req.body.message,time:r.now()} 
  plz r.table with 'dogechat'&
  dose insert with doc&
  dose then with much output
    plz res.send with output 
  wow&
wow&
```

On the frontend, I use the HTML5 `fetch` API to perform the POST request
whenever the user hits the enter key in the relevant input textbox. In the
`keyup` handler, I use Dogescript's `rly` keyword to see if the user hit the
enter key.

```javascript
such sendMessage much name text
  very doc is plz JSON.stringify with {name: name, message: text}
  very head is {'Content-Type':'application/json','Accept':'application/json'}
  plz fetch with '/api/send' {method: 'POST', headers: head, body: doc}&
  dose then with much output
    plz console.loge output
  wow&
wow

plz $("#message").keyup with much e
  rly e.keyCode is 13
    plz sendMessage with username e.target.value
    e.target.value is ''
  wow
wow&
```

The `fetch` API is one of my favorites. As a dog, I'm extremely good at fetch.
Well, I'm actually just good at the part that involves maniacally chasing the
ball and grabbing it with my mouth. I haven't quite mastered the finer points
of the second phase, the part that involves bringing the ball back so that
someone can throw it again. Fortunately, the `fetch` API is more consistent
where returning data is concerned.

# U can haz moar doge

After mastering highly technical skills like "sit" and "shake", I had no
trouble figuring out RethinkDB. You can learn it too, just check out our
[ten-minute guide][10-guide]. You can also view my demo application's full
source code [on GitHub][].

**Resources:**

* [The official Dogescript website][Dogescript]
* [The dogr.io cloud service][dogr.io]
* [Much moar doge][rdoge]

[Dogescript]: https://dogescript.com/
[left-pad]: https://www.npmjs.com/package/left-pad
[lang-ref]: https://github.com/dogescript/dogescript/blob/master/LANGUAGE.md
[repo]: https://github.com/dogescript/dogescript
[RethinkDBDash]: https://github.com/neumino/rethinkdbdash
[socket.io]: http://socket.io/
[Twilight Bark]: https://en.wikipedia.org/wiki/Twilight_bark
[dogr.io]: http://dogr.io
[Express]: http://expressjs.com/
[on GitHub]: https://gist.github.com/anonymous/f77e12122fd68ffa459c69b7e0ce0816
[10-guide]: /docs/guide/javascript/
[rdoge]: https://www.reddit.com/r/doge/

