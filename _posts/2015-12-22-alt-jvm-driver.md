---
layout: post
title: "Using the official RethinkDB Java driver in other JVM languages"
author: Ryan Paul
author_github: segphault
hero_image: 2015-12-22-alt-jvm-driver-banner.png
---

When we [released][] our official Java client driver earlier this month,
we highlighted the opportunity that it presents for developers who want to
use RethinkDB in other popular languages for the Java virtual machine.

In some JVM languages, our new client driver works right out of the box.
In other languages, there are some roadblocks that will require
third-party shims and other integration efforts. In this blog post, we
will look at how you can use the driver today in a selection of popular
JVM languages, including Scala, Clojure, Groovy, and Kotlin.

# Interoperability with Java 8 lambdas

Most languages for the JVM are designed with some degree of Java
interoperability, but not all of them have full support for the latest
features in Java 8. The RethinkDB Java driver relies on the language's
newly-added support for lambda expressions, which provide a concise way
for developers to pass anonymous functions to ReQL commands like `map`,
`reduce`, and `filter`.

Practically every language for the JVM already had its own take on lambdas
long before the feature arrived in Java 8. They all implement the feature
in subtly different ways, which poses a number of compatibility problems
when developers try to pass language-native anonymous functions over to
Java code that expects to receive Java 8 lambas. That's one of the biggest
sticking points that users can expect to encounter right now using the
RethinkDB Java driver in certain JVM languages, particularly Scala and
Clojure.

Under the hood, a Java 8 lambda compiles down to an anonymous inner class
with an `apply` method. In our Java client driver, we have a set of five
[`ReqlFunction`][reqlfunction] interfaces that describe anonymous
functions with different arities. Each one represents an anonymous
function with a specific number of parameters, between zero and four. An
anonymous function with one parameter, for example, uses the
`ReqlFunction1` interface. In the client driver source code, any method
that accepts an anonymous function uses one of those interfaces as the
parameter type.

When you use the RethinkDB Java driver in languages that don't
interoperate with Java 8, you have to manually create an anonymous class
that conforms with one of the `ReqlFunction` interfaces instead of using
the built-in anonymous functions supported by the language.


<!--more-->

# Groovy

[Groovy][] is a dynamic programming language with optional typing and rich
support for creating embedded domain-specific languages. It's also good
for scripting and interactive execution via REPL. It has good
interoperability with Java, which means that it works out of the box with
our native Java driver. The following example demonstrates how to import
the module, establish a connection to the database, perform a query, and
display the output:

```groovy
import com.rethinkdb.RethinkDB

r = RethinkDB.r
conn = r.connection().connect()
println(r.range(10).coerceTo("array").run(conn))
```

In Groovy, you can define an anonymous function by enclosing an expression
in curly braces. If your function only takes one parameter, you can simply
use the variable `it` as the implicit argument name instead of manually
defining a function signature. Groovy's anonymous functions are compatible
with Java 8 lambdas, so you can pass them to ReQL commands like `map` and
`filter`:

```groovy
r.range(10).filter({it.mod(2).gt(0)}).map({it.mul(2)}).sum().run(conn)
```

Many of the periods and parentheses in Groovy are optional: you can leave
them out and treat your ReQL expressions like an embedded domain-specific
language. The following code is equivalent to the previous example:


```groovy
r.range 10 filter {it.mod 2 gt 0} map {it.mul 2} sum() run conn
```

Groovy also supports operator overload, which you can use to make some
ReQL sub-expressions look more native. You can even reopen existing
classes and add operator overload methods, so we can overlay this behavior
on top of the existing Java client driver. For example, here's how you
modify the `ReqlExpr` class to overload multiplication so that the `*`
operator will perform the `mul` method:

```groovy
import com.rethinkdb.RethinkDB
import com.rethinkdb.gen.ast.*

ReqlExpr.metaClass.multiply = {mul(it)}

...

r.range 10 filter {it.mod 2 gt 0} map {it * 2} sum() run conn
```

Unfortunately, Groovy's equality checks and greater/less comparisons have
special behaviors that require overloaded implementations to return
boolean values. Since we can't overload those operators with
implementations that return ReQL expressions, we can't easily make those
operators behave as expected.

Groovy has built-in syntax for creating hash and array literals, which is
often useful when you insert new items into the database. You can also use
conventional property access to extract values from the JSON objects
returned by the client driver:

```groovy
r.table "fellowship" insert name: "Frodo", species: "hobbit" run conn

r.table "fellowship" filter {it.getField "species" eq "hobbit"} run conn each {
  println it.name
}
```

Let's try something really crazy. Although you probably wouldn't want to
do this in production, you can overload property access on ReQL variables
to make it behave like `getField` when you try to access a non-existent
property:

```groovy
import com.rethinkdb.RethinkDB
import com.rethinkdb.gen.ast.*

Var.metaClass.getProperty = {
  def meta = Var.metaClass.getMetaProperty it
  meta ? meta.getProperty(delegate) : getField(it)
}

...

r.table "fellowship" filter {it.species.eq "hobbit"} run conn each {
  println it.name
}
```

# Kotlin

[Kotlin][] is a relatively new statically-typed language developed by the
folks at Jetbrains. It has basic type inference, excellent Java
interoperability, and provides a nice balance between expressiveness and
safety. Like Groovy, it also works entirely out of the box with the
RethinkDB Java driver.  The following example demonstrates how to import
the module, establish a connection to the database, perform a query, and
display the output:

```kotlin
import com.rethinkdb.RethinkDB.r

fun main(args: Array<String>) {
  val conn = r.connection().connect()
  println(r.range(10).coerceTo("array").run<List<Any>>(conn))
}
```

Kotlin also has built-in support for anonymous functions that are
compatible with Java 8 lambdas. Although Kotlin isn't as permissive as
Groovy when it comes to optional punctuation, you can omit the parentheses
when you invoke a method that takes an anonymous function as its sole
argument:

```kotlin
println(r.range(10).filter {it.mod(2).gt(0)}.map {it.mul(2)}.sum().run<Long>(conn))
```

Kotlin supports operator overload on existing classes, but it has the same
limitations as Groovy with respect to comparison and equality checks. The
language will, however, let you enable infix invocation for specific
methods which you can use to clean up the ReQL commands that can't be
replaced with operators:

```kotlin
import com.rethinkdb.RethinkDB.r
import com.rethinkdb.gen.ast.*

operator fun ReqlExpr.times(exprA: Any) : Mul {
  return mul(exprA)
}

operator fun ReqlExpr.mod(exprA: Any) : Mod {
  return mod(exprA)
}

infix fun ReqlExpr.gt(exprA: Any) : Gt {
  return gt(exprA)
}

fun main(args: Array<String>) {
  val conn = r.connection().hostname("rethinkdb-stable").connect()
  println(r.range(10).filter {it % 2 gt 0}.map {it * 2}.sum().run<Long>(conn))
}
```

# Scala

[Scala][] is a powerful functional programming language with a
sophisticated type system. The following example demonstrates how to
import the module, establish a connection to the database, perform a
query, and display the output:

```scala
import com.rethinkdb.RethinkDB.r

val conn = r.connection().hostname("rethinkdb-stable").connect()
println(r.range(10).coerceTo("array").run(conn))
```

Scala's Java 8 interoperability is still under development, so you have to
manually create an anonymous class in order to use the RethinkDB Java
driver with Scala out of the box. The following example iterates over a
sequence of 10 elements, multiplies each value by 2, and then adds up the
results:

```scala
println(r.range(10).map(new ReqlFunction1 {
  override def apply(x: ReqlExpr) = x.mul(2:Integer)
}).sum().run(conn))
```

If you want to get an early look at the language's experimental support
for Java 8 compatibility, you can run Scala with the `-Xexperimental` flag
at the command line. With the flag enabled, you will be able to pass
native Scala functions to methods that expect to receive Java 8 lambdas:

```scala
r.range(10).map(x => x.mul(2:Integer)).sum().run(conn)
```

Like Groovy, Scala also lets you omit many of the periods and parentheses.
It also has a shorthand for writing anonymous functions--you can use an
underscore to represent the parameter. The following code is a shorthand
version of the previous example, with optional punctuation left out:

```scala
r range 10 map {_ mul(2:Integer)} sum() run conn
```

In some cases, you will still need to help Scala's type inference figure
out how to handle an anonymous function. For example, when you use the
ReQL `filter` command, you have to tell the Scala compiler that the
anonymous function you are passing is a `ReqlFunction1`:

```
r range 10 filter({_ mod 2 gt 0}:ReqlFunction1) coerceTo "array" run conn
```

Scala lets you define an [implicit class][implicit-class] to overload
operators, providing a more native way to express some ReQL operations:

```scala
import com.rethinkdb.RethinkDB.r
import com.rethinkdb.gen.ast.ReqlExpr

implicit class RichReqlExpr(original: ReqlExpr) {
  def *(x: Integer) = original mul x
  def %(x: Integer) = original mod x
  def >(x: Integer) = original gt x
}

..

r range 10 filter({_ % 2 > 0}:ReqlFunction1) map {_ * 2} coerceTo "array" run conn
```

In the example above, I only define versions of the method that take an
`Integer`. You'd likely also want to define versions that take `AnyRef` or
`ReqlExpr` so that you can use those overloaded methods with other types
besides literal number values.

Java 8 interoperability is an important part of the Scala 2.12 roadmap. If
the features that are currently hidden behind the `-Xexperimental` flag
work out of the box in version 2.12, it will go a long way towards making
the RethinkDB Java driver a viable choice for Scala users.

Though I'm relatively inexperienced with Scala myself, I imagine that more
seasoned Scala developers will be able to use implicits to smooth out the
remaining rough edges.

# Clojure

[Clojure][] is a functional programming language that is modeled after
Lisp. It is extremely flexible and expressive, with support for dynamic
typing and macros. The following example demonstrates how to import the
module, establish a connection to the database, perform a query, and
display the output:

```clojure
(defn -main [& args]
  (import com.rethinkdb.RethinkDB)
  (def r com.rethinkdb.RethinkDB/r)
  (def conn (-> (.connection r) .connect))
  (-> (.range r 10) (.coerceTo "array") (.run conn) println))
```

As a Lisp dialect, Clojure code is written with parenthetical
s-expressions and prefix notation. You can invoke conventional Java
methods by putting a period at the beginning of the method name. To
express a chained series of method invocations in order instead of with
nesting, you can use Clojure's thread-first macro (`->`), as demonstrated
in the previous example.

Unfortunately, Clojure doesn't yet offer complete interoperability with
the new features of Java 8. Several ReQL commands that rely on Java's
newly-added support for variadic arguments, for example, don't work out of
the box in Clojure. You have to manually wrap your parameters in an
`object-array`, like this:

```clojure
(-> (.expr r 5) (.add (object-array [5])) (.run conn) println)
```

When you define a function in Clojure, the underlying Java representation
is an [`IFn`][ifn] instance, which you can't pass to methods that expect
to receive Java 8 lambdas. Like Scala without the experimental flag,
Clojure requires you to manually create an anonymous inner class that
conforms with the Java client driver's various `ReqlFunction` interfaces.
You can use Clojure's `reify` function to create the anonymous inner
class:

```clojure
(-> (.range r 10)
    (.map (reify ReqlFunction1
          (apply [this x] (.mul x (object-array [2])))))
     .sum (.run conn) println)
```

It's likely that the situation will improve in the future when Clojure
develops better Java 8 interoperability. It's also likely possible for a
skilled Clojure developer to create shims and macros that ameliorate the
compatibility issues. For now, users are probably better off trying
[`clj-rethinkdb`][cljr], a third-party RethinkDB driver written natively
in Clojure.

# What about JRuby?

[JRuby][] is an implementation of the Ruby programming language that runs
on the JVM. It's a popular choice for developers who want the
expressiveness and dynamic execution of Ruby while retaining full access
to the Java library ecosystem. A lot of existing Ruby code that doesn't
rely on native extensions will work out of the box on JRuby. As such, we
recommend using the official [RethinkDB Ruby client driver][ruby-driver]
in the JRuby environment.

# Next steps

Want to try RethinkDB in your own JVM project? Check out our [ten-minute
guide to RethinkDB][10min] and refer to our Java client driver
[installation instructions][driverinstall] for details about how to use
the driver in Maven, Gradle, and Ant.

[released]: /blog/official-java-driver/
[reqlfunction]: https://github.com/rethinkdb/rethinkdb/blob/next/drivers/java/src/main/java/com/rethinkdb/gen/ast/ReqlFunction1.java
[Groovy]: http://www.groovy-lang.org/
[Kotlin]: https://kotlinlang.org/
[Scala]: http://www.scala-lang.org/
[Clojure]: http://clojure.org/
[JRuby]: http://jruby.org/
[implicit-class]: http://docs.scala-lang.org/overviews/core/implicit-classes.html
[ifn]: https://clojure.github.io/clojure/javadoc/clojure/lang/IFn.html
[cljr]: https://github.com/apa512/clj-rethinkdb
[ruby-driver]: /docs/install-drivers/ruby/
[10min]: /docs/guide/java/
[driverinstall]: /docs/install-drivers/java/
