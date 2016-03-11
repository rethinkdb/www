---
layout: post
title: "How to validate user input in a NoSQL web application"
author: Ryan Paul
author_github: segphault
---

Like many other modern JSON databases, RethinkDB is schemaless. The
developer doesn't have to define a fixed structure or specify field types
when creating a new table. In cases where validation is desirable, it's up
to the developer to build it into their application.

Shifting the responsibility for input validation from the persistence
layer to the application layer gives developers a lot of flexibility in
how they choose to implement the capability. This blog post demonstrates
several ways to validate input in Node.js web applications.

# Validator.js middleware

[Validator.js][validator] is a JavaScript library that contains a
collection of functions for validating and sanitizing strings. The
validators included in the library can check for a wide range of things,
like determining if a string is a credit card number or an e-mail address. 

Middleware libraries built on top of Validator.js are available for
popular Node.js web application frameworks like Koa and Express. I often
use [`koa-validate`][koa-validate], which wraps Validator.js and provides
additional methods for enforcing validation rules on incoming requests. As
a Koa middleware, it conveniently attaches its validation methods to the
request context.

The following example shows how to use `koa-validate` in a POST request
handler to make sure that the body includes a name and e-mail address. The
application will only insert a new record into the table if the user input
passes the validation rules:

```javascript
const app = require("koa")();
const router = require("koa-router")();
const r = require("rethinkdbdash")();

app.use(require("koa-body")());
app.use(require("koa-validate")());
app.use(router.routes());

router.post("/api/people/add", function*() {
  this.checkBody("name").len(2, 50);
  this.checkBody("email").isEmail();
  this.checkBody("age").optional().isInt();

  if (this.errors)
    this.throw(400, JSON.stringify(this.errors));

  this.body = yield r.table("person").insert({
    name: this.request.body.name,
    email: this.request.body.email,
    age: this.request.body.age
  });
});

app.listen(8000);
```

The validation rules in the example require a properly-formed e-mail
address and a name that is between 2 and 50 characters in length. They
also permit an optional age property, which must be an integer. When
validation fails, the application throws a 400 error with a JSON object
that describes the errors.

The `koa-validate` middleware is good for validating simple requests where
the properties don't have a lot of structural complexity. The library
doesn't provide APIs for rejecting extra properties, so you will likely
want to add some manual filtering for that case or craft your insert
operation to include only the properties that you want, as I did in the
example above.

One of the nice things about using this kind of middleware is that it
makes it easy to validate query fields and other elements of the request.
By comparison, the other techniques addressed in this article are
primarily just for handling JSON request bodies.

If you're using Express instead of Koa, you can use the
[`express-validator`][express-validator] middleware, which exposes a very
similar API.

# JSON Schema

[JSON Schema][] is a standard that allows users to define JSON formats in
JSON. There are a number of validation libraries that will check JSON
content to make sure that it conforms with a provided schema. Some popular
Node-compatible validators include [ajv][], [jsen][], and [themis][]. You
can't go wrong with any of those three, but I personally settled on ajv
for my own projects.

When writing JSON Schemas, you typically
[structure it in parts][structure] that reference each other in order
to maximize reuse. That composability is very useful, because it makes it
easy to describe the structure of documents with complex hierarchy. For
example, you can use mutually recursive references to model a structure
with potentially infinite depth.

JSON Schemas tend to be verbose and tedious to edit by hand, but the
machine readability gives you a lot of power. You can generate and
programmatically refactor your schemas. You can also generate other things
from the schemas. With a little creativity and effort, you can even share
your JSON Schemas between the frontend and backend. There are libraries
for [Angular][angular-schema] and [React][react-schema] that will let you
use JSON Schemas to generate forms and perform client-side validation in
the browser.

The following code is based on the previous example, but shows how you
would perform the same validation with `ajv`:

```javascript
const app = require("koa")();
const router = require("koa-router")();
const r = require("rethinkdbdash")();
const ajv = require("ajv")({
  removeAdditional: true
});

app.use(require("koa-body")());
app.use(router.routes());

const person = {
  type: "object",
  properties: {
    name: { type: "string", minLength: 2, maxLength: 50 },
    email: { type: "string", format: "email" },
    age: { type: "integer" }
  },
  required: ["name", "email"],
  additionalProperties: false
};

router.post("/api/people/add", function*() {
  let valid = ajv.validate(person, this.request.body);

  if (!valid)
    this.throw(400, JSON.stringify(ajv.errors));

  this.body = yield r.table("person")
                     .insert(this.request.body);
});

app.listen(8000);
```

In this example, I defined the schema in place with JavaScript. In a
larger application where you might have many different schemas, you can
write them all in an external JSON file that you load into `ajv`.

You'll notice that the `insert` operation in the example above is simpler
than the one from the `koa-validate` example. Configuring `ajv` with the
`removeAdditional` option will make the validator strip out any properties
that aren't explicitly defined in objects that have `additionalProperties`
set to false. That means we can store the whole request body directly in
the database, because the validator will remove any other superfluous
properties that are potentially dangerous to include in the document. If
you prefer to have validation fail when undesired properties are present,
you can simply not turn on the `removeAdditional` setting.

The JSON Schema standard includes a lot of keywords and formats that you
can use for validation. You can also use regular expressions. Some schema
validation libraries, like ajv, will even let you programmatically define
your own custom validation rules. To learn more about JSON Schema, you can
refer to the [official specification][schema-spec] or this
[handy online guide][schema-guide].

# A RethinkDB ORM

There are database client libraries that support data modeling and schema
enforcement, offering the kind of user experience that you'd typically get
from a SQL ORM. One prominent example is [Thinky][], a RethinkDB client
library that lets users define a schema for each table. When you use
Thinky's APIs for writing documents, it will perform a validation step to
make sure that the document conforms with the schema that you've defined
for the table.

Here's what the previous validation example looks like when it's
implemented with Thinky:

```javascript
const app = require("koa")();
const router = require("koa-router")();
const thinky = require("thinky")();

app.use(require("koa-body")());
app.use(router.routes());

const Person = thinky.createModel("person",
  thinky.type.object().schema({
    name: thinky.type.string().min(2).max(50).required(),
    email: thinky.type.string().email().required(),
    age: thinky.type.number().integer().optional()
  }).removeExtra());

router.post("/api/people/add", function*() {
  try {
    let person = new Person(this.request.body);
    this.body = yield person.saveAll();
  }
  catch (err) {
    if (err instanceof thinky.Errors.ValidationError)
      this.throw(400, JSON.stringify(err));
    else throw err;
  }
});

app.listen(8000);
```

You might have already noticed that the Thinky code example doesn't have
the standard line to import the RethinkDB client driver. That's because
Thinky itself is built on top of the `RethinkDBDash` client library.

When you create a model in Thinky, it produces a class that you can
instantiate to create a new document. In the example above, I made a new
document by creating a new instance of the `Person` class and passing it
the request body. When the route handler invokes `saveAll`, Thinky
attempts to validate the new document before inserting it into the
database.

Thinky throws an error when validation fails. Without the catch statement
in the example above, Koa would respond to the request with a 500 error
and provide no other feedback to the user. To make sure that the user
knows why the request failed, I instead throw a 400 error and pass back
the details.

It's worth noting that Thinky can do much more than just validation. It
also automatically creates tables for each model and provides support for
defining and resolving relations. To learn more about Thinky, refer to the
project's [official documentation][thinky-docs].

# Other options

There are a number of other libraries and frameworks that you can use for
JSON object validation. Describing them all is beyond the scope of this
blog post, but some popular options that might also want to consider are
[joi][] and [tcomb][].

If you'd like to learn more about building Node.js applications with
RethinkDB, you can refer to our [10 minute][10min] guide.

**Resources:**

* [The `koa-validate` validation middleware for Koa][koa-validate]
* [The official JSON Schema website][JSON Schema]
* [A list of libraries that support JSON Schema][schema-libs]
* [The `Thinky` ORM for RethinkDB][Thinky]

[validator]: https://github.com/chriso/validator.js
[koa-validate]: https://github.com/RocksonZeta/koa-validate
[express-validator]: https://github.com/ctavan/express-validator
[JSON Schema]: http://json-schema.org/
[ajv]: https://github.com/epoberezkin/ajv
[jsen]: https://github.com/bugventure/jsen
[themis]: https://github.com/playlyfe/themis
[structure]: http://spacetelescope.github.io/understanding-json-schema/structuring.html
[angular-schema]: http://schemaform.io/
[react-schema]: https://github.com/mozilla-services/react-jsonschema-form
[schema-spec]: http://json-schema.org/documentation.html
[schema-guide]: http://spacetelescope.github.io/understanding-json-schema/
[Thinky]: https://thinky.io/
[thinky-docs]: https://thinky.io/documentation/
[Joi]: https://github.com/hapijs/joi
[tcomb]: https://github.com/gcanti/tcomb-validation
[10min]: http://rethinkdb.com/docs/guide/javascript/
[schema-libs]: http://json-schema.org/implementations.html

