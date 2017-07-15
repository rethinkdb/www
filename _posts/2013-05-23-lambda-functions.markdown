---
layout: post
title: All about lambda functions in RethinkDB queries
tags:
    - drivers
    - ReQL
author: Bill Rowan
author_github: wmrowan
---

It's no secret that ReQL, the RethinkDB query language, is modeled after
functional languages like Lisp and Haskell. The functional paradigm is
particularly well suited to the needs of a distributed database while being
more easily embeddable as a DSL than SQL's ad hoc syntax. Key to functional
programming's power and simplicity is the anonymous (aka lambda) function.

This post covers all aspects of lambda functions in ReQL from concept to
implementation and is meant for [third][rethinkdb-net] [party][rethinkgo]
[driver][lethink] [developers][php-rql] and those interested in functional
programming and programming language design. For a more practical guide to
using ReQL please see our [docs][] where you can find [FAQs][],
[screencasts][], an [API reference][], as well as various tutorials and
examples.
<!--more-->

[rethinkdb-net]: http://github.com/mfenniak/rethinkdb-net
[rethinkgo]: http://github.com/christopherhesse/rethinkgo
[lethink]: http://github.com/taybin/lethink
[php-rql]: http://github.com/danielmewes/php-rql
[docs]: /docs
[FAQs]: /docs/faq
[screencasts]: /screencast
[API reference]: /api

All examples make use of the official Python driver, but nothing
in this post is Python-specific and all examples should translate directly to
the other officially supported languages.

# What's the point of lambda functions in a database query language?

To grok ReQL, it helps to understand functional programming. Functional
programming falls into the declarative paradigm in which the programmer aims to
*describe* the value he wishes to compute rather than *prescribe* the steps
necessary to compute this value. Database query languages typically aim for the
declarative ideal since this style gives the query execution engine the most
freedom to choose the optimal execution plan. But while SQL achieves this using
special keywords and specific declarative syntax, ReQL is able to express
arbitrarily complex operations through *functional composition*. To understand
the contrast, consider the following SQL query.

```sql
SELECT * FROM users WHERE users.age >= 18
```

The body of the `WHERE` clause aims to describe the properties rows from the
table must satisfy to be of interest to the rest of the query.  The SQL engine
might compile this query to some version of the following imperative algorithm.

```python
results = []
for user in users:
    if user['age'] >= 18:
        results.append(user)
```

Those familiar with functional programming idioms might recognize this pattern
as equivalent to a `filter` which abstracts away the `for` loop, `if` test, and
result aggregation. Only the actual test, provided to `filter` as a boolean
function on a single element, must be supplied by the user.

Python supports two different syntaxes for specifying code blocks. The older
`def fun(args...): ...` statement and a newer `lambda args...: ...` expression.
The key advantage of the latter syntax is that it is an expression that
evaluates to a first class Python value that can be saved to a variable, passed
to functions, and declared in-line. With this feature, the ReQL version of the
original SQL query can be expressed succinctly with *native* Python syntax.

```python
r.table('users').filter(lambda user: user['age'] >= 18)
```

This leads us to the first and most important answer to our question. Used
correctly, lambda functions allow a complex algorithm to be easily decomposed
into its constituent parts. This supports the goal of a declarative syntax by
splitting out code unique to the computation at hand from the boilerplate best
left to the query execution engine.

The main advantage of functional programming though comes when we we begin to
*compose* functions to create more complex queries. Consider what happens when
we modify the original SQL query to select just one field from each row.

```sql
SELECT team_id FROM users WHERE users.age >= 18
```

To do the equivalent in ReQL we transform the stream of rows produced by the
`filter` operation with a `map` operation, perhaps the best known functional
idiom, that "selects" the `team_id` field from each row to produce a stream of
just these values.

```python
r.table('users').filter(lambda user: user['age'] >= 18).map(lambda user: user['team_id'])
```

The original stream of values from the table is first fed into the `filter` and
transformed into a stream of just rows that match the pattern. This result is
then fed into the `map` which transforms it into a stream of just the relevant
fields. This technique can be repeatedly applied to construct more and more
complex queries. Let's take it further and actually do something useful with
those team id's by getting the names of all teams with at least one adult
member.

```sql
SELECT DISTINCT teams.team_name
FROM users, teams
WHERE users.age >= 18 AND
    users.team_id = teams.team_id
```

The following ReQL translation emphasizes the chain of operations this implies.

```python
(r.table('users').filter(lambda user: user['age'] >= 18)
  .map(lambda user: user['team_id'])
  .map(lambda team_id: r.table('teams').get(team_id))
  .map(lambda team: team['team_name'])
  .distinct())
```

Notice how Python's object oriented syntax supports composition through
chaining over the nesting style of Lisp or C, avoiding the telescoping parens
so closely associated with Lisp and functional programming generally. More
canonical ReQL would collapse the sequential maps to leave a terser expression.

```python
(r.table('users').filter(lambda user: user['age'] >= 18)
  .map(lambda user: r.tables('teams').get(user['team_id'])['name'])
  .distinct())
```

This query achieves the same result as the original SQL without being any more
prescriptive about how to execute the query. Furthermore, it is expressed as
100% native Python using the built-in tools and syntax Python developers are
already familiar with.

# Variable binding

The simplest ReQL API function that takes a lambda function as an argument is
`do` which immediately applies its function argument to its receiver. It can be
thought of as a one element `map`. Let's look at a simple example.

```python
>>> r.expr("foo").do(lambda x: x + "bar").run()
'foobar'
```

This curious little tool actually serves a much wider purpose than it seems to
at the surface for it is **the** way to bind variables and manage variable
scopes in ReQL.

To illustrate how this is useful, let's say you want to square a ReQL number.
This requires referencing the value twice. You can recompute the value to make
the second reference, i.e. `(...some query...) * (...repeated...)`, but this is
wasteful and wouldn't work at all if you had to rely on a non-deterministic
computation. Instead, we can compute the value once and bind it to a function
argument by using `do`.

```python
>>> r.expr(12).do(lambda x: x * x).run()
144
```

The lambda functions used in other constructs like `map` and `reduce` also
create variable scopes. These can be nested with `do` to manage variables of
different lifetimes. Let's say that you want to transform a sequence of values
into percentages of the whole by dividing through the sum. By using a `do` to
bind the sum we can refer to it in each invocation of the mapping function
without having to recompute it.

```python
>>> r.expr([1,2,3,4]).do(lambda seq:
...     seq.reduce(lambda x,y: x + y).do(lambda total:
...         seq.map(lambda val: val / total)
...     )
... ).run()
[0.1, 0.2, 0.3, 0.4]
```

A similar technique is used to pass ReQL values to JavaScript terms. The ReQL
JavaScript term passes a text string representing a JavaScript snippet to V8 as
if you'd called `eval` within your JavaScript environment. In order for this
feature to be useful there must be some way to pass values from the ReQL stack
to the JavaScript environment. The solution, as you might have guessed, is to
use lambda functions.  Any JavaScript term that evaluates to a JavaScript
function object can be used anywhere a ReQL lambda function is expected,
including in `do`.  Here's how we might rewrite the original squaring example
to use JavaScript.

```python
>>> r.expr(12).do(r.js('(function(x) { return x * x; })')).run()
144
```

A more realistic example would actually leverage the additional value that
JavaScript execution provides.  Let's say you want to find all users in your
user table with Scottish sounding names (which we define as containing a 'Mc'
or 'Mac' prefix). Though regular expressions are not currently available in ReQL
natively we can access the functionality through ReQL's JavaScript support.  To
pass the name string to the JavaScript snippet we will define a JavaScript
function that accepts it as an argument. Since `filter` expects a lambda
function anyway, we can simply pass the JavaScript term directly to the
`filter` in place of an ordinary ReQL function.

```python
>>> r.table('users').filter(r.js("""(function(user) {
...    return /^((Mac)|(Mc))[A-Z]/.test(user.last_name);
... })""").run()
[{'user_id': 1, 'first_name': 'Douglas', 'last_name': 'MacArthur'}, ...]
```

# How lambda functions are processed by the drivers

Those who have made it this far may be by now wondering just how the pure
Python code samples given above are actually transformed into something
executable by the RethinkDB server. While this process may be of primary
interest to third party driver developers, a peek under the hood will serve
casual ReQL programmers as well.

Unlike SQL, ReQL is not transmitted to the database server as plain text.
Instead, ReQL client drivers are responsible for implementing an embedded
domain specific language and serializing queries to a binary wire format using
Google's excellent pan-lingual Protocol Buffer serialization format.

While there is no canonical text representation of the ReQL wire format we can
use S-expressions to describe it's structure. As an example, here's how a
simple mathematical query would be translated by the Python driver.

```python
r.expr(2) * (2 % 3)
```
```
(mul 2 (mod 2 3))
```

Lambda functions passed to API functions like `do` and `filter` also get
serialized in this way. Under the hood, `do` is translated to a term called
"funcall", and it's lambda function argument to a term called "func". A `func`
term is comprised of two pieces, an array of argument names (given as integers)
and a term giving the body of the function. The body term may then reference
the arguments by constructing `var` terms with the appropriate argument names.
This is the same squaring query from above translated the wire format.

```python
r.expr(12).do(lambda x: x * x)
```
```
(funcall (func [1] (mul (var 1) (var 1))) 12)
```

Understanding just how the driver translates a Python lambda function into this
serialized form requires a little bit of understanding of how it translates
other bits of the embedded language.

Just as the symbols in your Python source code represent the values that will
eventually be computed during runtime, the ReQL query objects constructed at
runtime represent the values that will eventually be computed when the query is
executed on the server. These objects are not merely references though, they
actually encode the whole process of computing the value. Further operations on
these "values" augment the computation represented and return an object
representing the modified computation.  The result is a tree where each node
represents a step in the computation. In fact, this result looks just like the
serialized S-expression format presented above in tree form.  Serializing this
on the wire is then just a simple depth first pass over the tree.

In principle, lambda function serialization is no different, though the process
may be unintuitive at first glance. First, `var` terms are constructed for each
of the function's formal arguments. The actual Python lambda function is then
invoked on these variable references and the return value is used as the body
term of the ReQL lambda function. Remember, this value doesn't just represent
the value returned by the lambda function, it also encodes the whole process of
computing that value, fully encapsulating the computation represented by the
lambda function.

Let's walk through a more comprehensive example to see how this works. Here's
how we might compute the average age of all the users in your user table.

```python
r.table('users').map(lambda user: user['age']).reduce(lambda x,y: x + y) /
    r.table('users').count()
```

To construct the `map` node we must serialize the one argument lambda function
that extracts the 'age' field from a single row in the table. The first step is
to construct a variable reference to represent the "user" argument, the node
`(var 1)`. Next we invoke the actual lambda function on this node. The body of
the function then calls the overloaded `__getitem__` method on the `var` term.
This constructs a node with the form `(getattr (var 1) 'age')` which becomes
the body of our function. The `map` term encloses both the table reference and
this function term as its arguments.

```
(map (table 'users') (func [1] (getattr (var 1) 'age')))
```

This result is then passed to `reduce` which is constructed in a similar manner
though this time with two arguments.

```
(reduce (map ...) (func [2,3] (add (var 2) (var 3))))
```

The last step is to divide this result by the size of the table for the final
query.

```
(div
    (reduce
        (map
            (table 'users')
            (func [1] (getattr (var 1) 'age'))
        )
        (func [2,3] (add (var 2) (var 3)))
    )
    (count (table 'users'))
)
```

Glossed over above is the algorithm for assigning integer variable names to
each of the arguments. This is actually more difficult than you might think.
Within the executing Python code the original names assigned by the programmer
have been lost and the driver must come up with an alternative scheme for
assigning names. While intuition suggests simply using a counter that numbers
arguments one by one for each function, this approach is prone to a problem
known as variable capture. Consider a simple query that makes use of nested
scopes.

```python
r.expr("foo").do(lambda x: r.expr("bar").do(lambda y: x))
```

The inner function is supposed to return the first argument of the outer
function, "foo", not the first argument of the inner function, "bar". Can you
spot the problem that occurs when we use a separate argument counter for each
function?

```
(funcall (func [1] (funcall (func [1] (var 1)) "bar")) "foo")
```

We've created an ambiguity between the two arguments by assigning them the same
name and now can't know to which the variable is meant to refer. The simplest
way to resolve the problem is to assign all arguments a unique name and the
easiest way to do this is with a global counter.

The process of serializing lambda functions works exactly the same way in all
the official drivers and we encourage third party driver developers to do
something similar. Having ReQL lambda functions represented by native lambda
functions in the host language vastly improves legibility of queries and
reduces confusion. As you may have noticed, it can even be hard to tell that
ReQL code is not native to the host language!
