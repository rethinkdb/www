---
layout: post
title: "Developer Preview: RethinkDB now available for Windows"
author: Ryan Paul
author_github: segphault
---

We're pleased to announce today that RethinkDB is
[now available for Windows][wininstall]. You can download a Developer Preview
of our Windows build, which runs natively on Microsoft's operating system.

Support for Windows is one of the features
[most frequently requested][ghissues-win] by RethinkDB users.
Encouraged by the clear demand, we launched an ambitious engineering project
to make Windows a first-class citizen inside the RethinkDB code base. The
undertaking required a year of intensive development, touching nearly every
part of the database.

To try today's Developer Preview, simply
[download the executable from our website][windl] and double-click it on your
computer. We're making the preview available today so that our users can start
exploring RethinkDB on Windows and help us test it in the real world. You
shouldn't trust it with your data or use it in production environments yet.
It's also not fully optimized, so you might not get the same performance that
you would from a stable release.

<!--more-->
  
Starting with the upcoming RethinkDB 2.3 release, we'll provide official
Windows builds for each version of RethinkDB alongside our binary packages for
Linux and Mac OS X. Any developer who wants to build RethinkDB applications on
a Windows PC can get started more easily than ever before, developing locally
without provisioning a Linux server or relying on cloud hosting providers. As
our Windows support continues to mature, developers can look forward to
deploying RethinkDB natively in Windows Server environments.

## Extending RethinkDB to Windows

Under the hood, RethinkDB includes a tremendous amount of low-level plumbing
built on platform-specific APIs. We decided early in the project that we would
not settle for less than full, native Windows support. You won't find any POSIX
compatibility layers or other similar hacks--RethinkDB uses native Windows APIs
on the Windows platform.

Some key areas that required considerable engineering effort include threading,
disk and network I/O, and the event loop. The underlying APIs that developers
use to perform asynchronous I/O on Windows differ from their Linux counterparts
in some notable ways. On Linux, developers use `epoll` to get notifications
that let them know when a descriptor is ready for reading or writing. On
Windows, developers use I/O Completion Ports (`IOCP`), which entails queuing up
asynchronous operations that emit notifications when they succeed or fail.

We considered adopting Node's `libuv` as a cross-platform abstraction layer for
asynchronous I/O, but many of the underlying design decisions in `libuv` clash
with decisions that we've made in the RethinkDB core. Ultimately, using an
abstraction layer like `libuv` would have required us to make more changes to
code that we currently share between Windows and Linux. We chose instead to
manually add Windows-compatible code paths to handle the platform-specific I/O.

We also had to incorporate Windows into our build system and get the database
to compile natively with Microsoft's own C++ compiler. The build system work
proved especially taxing, because we had to ensure that all the third-party
open source libraries we use in the database build consistently on Windows as
well as Linux and Mac OS X.

## Build a RethinkDB app on Windows in Visual Studio

If you're a seasoned .NET developer and you want to get started with RethinkDB,
check out the [C# client library][csharp-driver] created by Brian Chavez. Brian
based his C# library on our own official Java driver, which we
[released in December][java-driver].

To demonstrate how to build RethinkDB applications on Windows in Visual Studio,
we built a simple ASP.NET chat demo with [SignalR][] and Brian's C# RethinkDB
driver. SignalR is a framework for performing realtime updates in ASP.NET. It
uses WebSockets to bind a JavaScript frontend with an ASP.NET backend,
providing an abstraction layer for RPC and event propagation. 

You can use NuGet to add the RethinkDB driver and SignalR to your ASP.NET
project:

<img src="/assets/images/posts/2016-02-10-nuget.png">

When you use SignalR, you create C# "hub" objects with methods that are
remotely accessible from the frontend. The hub in our chat demo has a method
called `Send` that adds new messages to the database. It uses the RethinkDB
client library to establish a connection with the database cluster and insert a
new record. Each record includes three properties: the name of the user, the
text of the message, and a timestamp.

```csharp
class ChatMessage
{
    public string username { get; set; }
    public string message { get; set; }
    public DateTime timestamp { get; set; }
}

public class ChatHub : Hub
{
    public static RethinkDB r = RethinkDB.r;

    public void Send(string name, string message)
    {
        var conn = r.connection().connect();
        r.db("chat").table("messages")
         .insert(new ChatMessage {
             username = name,
             message = message,
             timestamp = DateTime.Now
         }).run(conn);
        conn.close();
    }
}
```

In the frontend HTML file, you can use the SignalR client library to connect to
the hub and invoke the `Send` method exposed by the `ChatHub` class. SignalR
automatically handles the remote procedure call (including serialization of the
parameter values on both sides), making it possible to transparently call
backend C# methods on the client:

```javascript
<script src="Scripts/jquery.signalR-2.1.2.min.js"></script>
<script src="signalr/hubs"></script>

<script type="text/javascript">
  var chat = $.connection.chatHub;
  chat.server.send("ryan", "This is a chat message");
</script>
```

Now that you have the code in place to add new messages to the database table,
you want to make the ASP.NET backend broadcast each new message to all of the
connected users. 

When you perform a RethinkDB query that includes the `changes` command, the
database will automatically push you updates to the query result set. You can
use a changefeed to track each new record added to the database's message
table. The following C# class on the backend sets up a changefeed and uses the
`ChatHub` to broadcast new messages to the frontend:

```csharp
class ChangeHandler
{
    public static RethinkDB r = RethinkDB.r;

    async public void handleUpdates()
    {
        var hub = GlobalHost.ConnectionManager.GetHubContext<ChatHub>();
        var conn = r.connection().connect();
        var feed = r.db("chat").table("messages")
                    .changes().runChangesAsync<ChatMessage>(conn);

        foreach (var message in await feed)
            hub.Clients.All.onMessage(
                message.NewValue.username,
                message.NewValue.message,
                message.NewValue.timestamp);
    }
}
```

On the frontend, you can attach a JavaScript function to the `onMessage` event.
The function will execute every time the backend calls the `onMessage` method:

```javascript
var chat = $.connection.chatHub;
chat.client.onMessage = function(username, message, timestamp) {
  console.log(username + ": " + message);
}
```

In our sample demo, we built the user interface for a frontend client with
[Vue.js][vue], a lightweight MVC framework that supports data binding. You
could just as easily use React or Knockout if you prefer. 

<img src="/assets/images/posts/2016-02-10-demo-app.png">

To see the application in action, you can [download the full source code][demo-app]
from GitHub and run it yourself in Visual Studio.

## Next Steps

If you'd like to get started with RethinkDB on Windows, [download][wininstall] the
Developer Preview today. After you run the database, you can follow our
[ten-minute guide][10min] to learn more.

Want to help us make RethinkDB better? You can join the development process
[on GitHub][rdbgh]. We're looking forward to [receiving bug reports][issues]
and other feedback as users test the new Windows build.

**Resources:**

* [Install RethinkDB on Windows][wininstall]
* [Learn more about the RethinkDB C# driver][csharp-driver]
* [Learn more about SignalR][SignalR]
* [See our sample SignalR app on GitHub][demo-app]

[wininstall]: /docs/install/windows/
[windl]: https://download.rethinkdb.com/windows/rethinkdb-dev-preview-0.zip
[ghissues-win]: https://github.com/rethinkdb/rethinkdb/issues/1100
[issues]: https://github.com/rethinkdb/rethinkdb/issues
[csharp-driver]: https://github.com/bchavez/RethinkDb.Driver
[rdbgh]: https://github.com/rethinkdb/rethinkdb
[java-driver]: https://rethinkdb.com/blog/official-java-driver/
[vue]: http://vuejs.org/
[10min]: /docs/guide/ruby/
[SignalR]: http://www.asp.net/signalr
[demo-app]: https://github.com/rethinkdb/aspnet-signalr-chat
