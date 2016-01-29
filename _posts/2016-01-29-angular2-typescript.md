---
layout: post
title: "How Angular is reinventing itself with version 2 and TypeScript"
author: Ryan Paul
author_github: segphault
hero_image: 2016-01-29-angular-typescript-banner.png
---

AngularJS began to gain serious traction in 2012, attracting significant
popularity as it cut through the noise in the crowded frontend framework
landscape. Angular enthusiasm was quick to wane, however, as the framework
fell victim to the [trough of disillusionment][hype-cycle] that sits on the
other side of the hype cycle. React is the new darling, perched on the peak
of inflated expectations where it will likely be displaced by some shiny
thing that comes along in the future.

The original AngularJS offered some good ideas, but it wasn't a very good
framework in practice. Its successor, Angular 2, addresses many
shortcomings while retaining many of the strengths that made the original
framework popular. With the benefit of a clean break, the developers behind
Angular 2 were able to exorcise many of the framework's most pernicious
demons.

<!--more-->

Users can finally put to rest the shambling horde of gratuitous
`$scope.$apply` invocations that seemingly haunt every dark corner of
AngularJS apps. And you can put a sharpened stake through the arcane
parameter scraping hacks in the dependency injection system that used to
bite during minification and other post-processing operations.

In short, almost everything is less awful. You're still stuck with much of
the distressingly esoteric terminology that the Angular developers
afflicted upon the world, but I think many are willing to live with the
lingering horror of ugly phrases like "directive transclusion" as long as
nobody will never again have to degrade themselves by typing
`$scope.$apply`.

Existing Angular enthusiasts will find that the things they know and love
still endure in the framework's new iteration. It is highly conducive to
automated testing, you can compose your application with custom directives,
and the data binding system supports one-way and two-way bindings against
conventional JavaScript objects.

Angular 2 is still under heavy development, but I recently decided to take
an early look. I used the latest Angular 2 beta to build a simple realtime
chat application, paired with a backend built on Node.js and RethinkDB. I
wrote the demo application in TypeScript, a language that pairs JavaScript
with a flexible type system. I used TypeScript for both the Node.js backend
and the Angular 2 frontend.

# TypeScript

[TypeScript][] allows the developer to annotate variables and function
parameters with type declarations, which external tools can use to support
features like static type checking and autocompletion. It is designed as a
superset of JavaScript, adding new features without compromising the
expected behavior of the original language. It supports a wide range of ES6
features, including the `class` keyword and arrow functions. Like
CoffeeScript, TypeScript code transpiles to browser-friendly JavaScript,
which means that you can use it to build frontend web applications.

TypeScript support is optional in Angular 2, but adopters will quickly find
that it's a great match for the framework. The Angular developers built the
new version of the framework to take advantage of TypeScript's strengths.
They even collaborated with TypeScript's core team at Microsoft to foster
new language features that address specific Angular needs.

When building an Angular 2 application with TypeScript, you define each new
directive in its own class. TypeScript decorators provide a convenient way
to specify component metadata and properties, including the custom tag name
and the list of external directives that you want the dependency injection
system to make available for use.

TypeScript's approach to type checking is unobtrusive and conducive to
incremental adoption. You can choose to apply type declarations wherever
you want, and leave them out when you don't need them. You can also easily
mix conventional ES6 code and TypeScript code in the same project without
worrying about the boundaries or how the type system will affect
interoperability.

In addition to simplifying Angular component definitions, TypeScript can
offer a measure of additional safety and convenience throughout your
project. When you work with arbitrary JSON data from a NoSQL database or a
REST API, for example, you can use a TypeScript interface to formalize
property access and avoid errors.

Consider a case where you are building a game and you have information
about user scores. You could define the following TypeScript interface to
describe the structure of the JSON objects that you store in your database:

```typescript
export interface UserRecord {
  id: string;
  username: string;
  points: number;
}
```

When you fetch the associated records from your database, you can use a
simple `Array<UserRecord>` type declaration to indicate that you are
retrieving an array of objects that conform with the interface. In the
following example, written in Node.js on the backend, I retrieve the
documents from RethinkDB and iterate over them:

```typescript
var r = require("rethinkdb");

(async function() {
  try {
    var conn = await r.connect({host: HOST});
    var users : Array<UserRecord> = await r.table("points")
                                            .orderBy(r.desc("points"))
                                            .limit(10).run(conn);
    conn.close();

    for (var user of users)
      console.log(`User ${user.username} has ${user.points} points`);
  }
  catch (err) {
    console.log("Failed to retreive user records from database.");
  }
})();
```

If you write code that accesses an undefined property, the TypeScript
compiler will save you from shooting yourself in the foot. It will also
intelligently offer autocompletion whenever you start accessing a property
on a record in the `users` array.

<img src="/assets/images/posts/2016-01-29-angular2-property-error.png">

In the code above, you will also notice that I was able to use ES7 `async`
and `await` keywords, which TypeScript supports experimentally. You can use
`async` and `await` to flatten and simplify code that expresses the flow of
asynchronous operations. Out of the box, you can `await` any operation that
returns a promise. Another major advantage of using `await` instead of
`.then` is that it works seamlessly with conventional JavaScript exception
handling.

You can share interface definitions, like the `UserRecord` example above,
between frontend and backend code--using it on both sides of the stack. If
you use a REST API or WebSockets to pass the underlying JSON objects to the
frontend, you still get the same property access checks and basic type
safety anywhere you use a type assertion to apply the interface.

It's important to keep in mind that interface definitions and other
features of the TypeScript type system only provide compile-time checking.
In the case of the `UserRecord` definition, for example, it doesn't perform
any checks at runtime to ensure that the objects you receive actually match
the structure that you define.

To get the full advantages of TypeScript, you will likely want to use a
development environment that supports TypeScript integration. I built my
demo application in GitHub's open source Atom editor, with the
[atom-typescript][] plugin. It automatically compiles your TypeScript code
into JavaScript when you save a file, exposing any errors that it finds
along the way. It also has highlighting, autocompletion, symbol browsing,
rename refactoring, and a number of other features.

Other editors that support TypeScript development include [Visual Studio
Code][vsc] and [WebStorm][]. You can also use command-line tools, though
that doesn't provide quite the same degree of workflow integration.

# Angular 2

Angular 2 applications are built with components, discrete units of
functionality that developers compose to achieve the desired result. Each
component is an object that includes template markup, metadata, and
supporting functions. When you build an Angular 2 application with
Typescript, each component is a class definition. With the help of a
special `Component` decorator, you can annotate the class definition with
relevant component metadata like the component's tag name, exposed
properties, and emitted events. The following code example, a complete
component from my chat demo, displays a single message sent by a user:

```typescript
import {Component, View} from "angular2/core";
import {ChatMessageRecord} from "../interfaces";

@Component({
  selector: "chat-message",
  properties: ["message: message"]
})
@View({
  template: `
  <div class="message">
    <div class="sender">{{message.user}}</div>
    <div class="time">&nbsp;({{time | date:'jms'}})</div>
    <div class="text">{{message.text}}</div>
  </div>
  `,
})
export class ChatMessage {
  message: ChatMessageRecord;

  get time() {
    return new Date(this.message.time);
  }
}
```

As you can see, the entire component is defined with a class called
`ChatMessage`. The `selector` field in the `@Component` decorator indicates
that `chat-message` is the name of the tag, which you can use in template
markup when you want to create an instance of the component. The
`properties` field tells the component how to expose class properties as
tag attributes in template markup where the component is consumed. When you
use the `ChatMessage` component, it will look a bit like this:

```html
<chat-message [message]="someMessage"></chat-message>
```

You use the selector name to create the component instance, and then you
can use data binding to attach the value of a variable to the message
attribute. The square brackets around the attribute are used to signify
that the data binding is one-directional instead of a two-way binding.

The `@View` decorator typically contains the component's template and
template metadata. In this particular case, I used a multiline string to
embed the template markup directly. When the markup is more complicated,
however, you would typically just provide the path of an external HTML
file.

The `@View` decorator is also used for dependency injection. Like its
predecessor, Angular 2 uses dependency injection to make a given unit of
functionality available in a particular context. When a component uses
other components in its markup, you add `directives` property to the
`@View` decorator with an array of the components that you want to inject. 

In my chat demo's top-level application component, for example, I use three
of my own custom components in addition to several from Angular's  standard
libraries. In the following source code, you can see how I use the
`directives` property to inject the imported components:

```typescript
import {Component, View} from "angular2/core";
import {NgFor, NgSwitch, NgSwitchWhen} from "angular2/common";

import {ChatMessage} from "./components/message";
import {ChatLogin} from "./components/login";
import {ChatInput} from "./components/input";

import {ChatMessageRecord} from "./interfaces";

@Component({selector: "chat-app"})
@View({
  template: `
  <div class="inner" [ngSwitch]="username == undefined">
    <template [ngSwitchWhen]="true">
      <chat-login (login)="onLogin($event)"></chat-login>
    </template>
    <template [ngSwitchWhen]="false">
      <div class="messages">
        <chat-message *ngFor="#m of messages" [message]="m"></chat-message>
      </div>
      <chat-input (message)="onMessage($event)"></chat-input>
    </template>
  </div>
  `,
  directives: [
    NgSwitch, NgSwitchWhen, NgFor,
    ChatMessage, ChatInput, ChatLogin]
})
export class ChatApp {
  username: string
  messages: Array<ChatMessageRecord>

  onMessage(message: string) {
    fetch("/api/messages/create", {method: "post",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({user: this.username, text: message})
    });
  }

  async onLogin(username: string) {
    this.username = username;
    this.messages = await (await fetch("/api/messages")).json();
    io.connect().on("message", message => this.messages.push(message));
  }
}
```

The `NgSwitch` component lets me conditionally choose between showing the
login form or a list of messages depending on whether the user has logged
in. The `NgFor` component lets me display a series of messages bound to an
array. You can see that I'm using it on my own custom `ChatMessage`
component, which encapsulates the logic for displaying a message.

When the user logs in, the application use the HTML5 `fetch` API to
retrieve the initial messages. It also connects to Socket.io so that it can
receive updates. When new messages arrive, it appends them to the array
where the message list is bound. There's also an `onMessage` event handler
that fires when the user sends a message from the `ChatInput` component. It
uses a `POST` request to push the user's new message to the server.

Angular 2 is clearly a lot more intuitive than its predecessor. The example
above is relatively straightforward with behavior that is easy to follow if
you've ever worked with Angular 1.x or a similar frontend MVC framework.

There are a number of other noteworthy ways in which Angular 2 improves on
its predecessor. For example, Angular 2 makes 
[extensive use][observable-example] of [RxJS][] observables. Under the hood,
[change detection][change-detection] and data binding are also more performant
and flexible. It relies on [Zone.js][] to obviate the need for
conventional dirty checking and `$scope.$apply`.

# How does it compare to React and Angular 1.x?

Angular 2 is radically different from its predecessor. Although the
decision to pursue a clean break is understandably controversial, the
result is a much stronger framework. It's not really clear, however, if
that's going to be enough to attract and sustain a large audience. Now that
the React hype cycle has displaced Angular's, it's going to be hard for
Angular 2 to overcome that loss of momentum.

The Angular 2 component model and tight integration with Typescript are
very impressive, but don't help to differentiate it much from React. It's
worth noting that Typescript [supports][jsx-ts] React's JSX template
language, which means that you can also comfortably use Typescript to build
React components.

As a matter of taste, some developers might prefer Angular's clean,
declarative approach to template markup over React's JSX. Another key
difference is that Angular aims to provide a more comprehensive ecosystem
whereas React largely focuses on view rendering. Many React adherents view
React's simplicity and tight focus as a selling point, however.

It's not clear that Angular 2 will win back many of the React converts, but
developers who liked Angular and left it behind to get away from the
performance overhead of dirty checking and the poor ergonomics of
`$scope.$apply` can happily return knowing that those warts are now
vanquished.

For existing Angular 1.x users, Angular 2 offers clear benefits in
performance and ease of development. Migrating existing applications is
going to be painful, but possible: the framework includes an
[adapter][upgrade-adapter] that enables incremental upgrades, letting
developers mix Angular 1.x and Angular 2.x components in the same
application. For existing Angular 1.x shops, switching to 2.x for new
projects will likely be beneficial.

# Next steps

I've published the full source code of my chat demo on [GitHub](#). You can
check it out and try it yourself. If you'd like to learn more about
RethinkDB, visit our [ten-minute guide][10min].

[TypeScript]: http://www.typescriptlang.org/
[hype-cycle]: https://en.wikipedia.org/wiki/Hype_cycle
[atom-typescript]: https://atom.io/packages/atom-typescript
[vsc]: https://code.visualstudio.com/
[WebStorm]: https://www.jetbrains.com/webstorm/
[observable-example]: http://blog.thoughtram.io/angular/2016/01/06/taking-advantage-of-observables-in-angular2.html
[RxJS]: http://reactivex.io/
[change-detection]: http://victorsavkin.com/post/110170125256/change-detection-in-angular-2
[Zone.js]: https://github.com/angular/zone.js/
[jsx-ts]: https://github.com/Microsoft/TypeScript/wiki/JSX
[upgrade-adapter]: https://angular.io/docs/ts/latest/guide/upgrade.html
[10min]: /docs/guide/javascript/
