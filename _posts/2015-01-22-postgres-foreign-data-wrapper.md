---
layout: post
title: "Query RethinkDB tables from PostgreSQL with foreign data wrappers"
author: Ryan Paul
author_github: segphault
---

Rick Otten ([@rotten][]) recently released a [foreign data wrapper][1] for
PostgreSQL that provides a bridge to RethinkDB. The wrapper makes it possible
to expose individual tables from a RethinkDB database in PostgreSQL, enabling
users to access their RethinkDB data with with SQL queries.

[@rotten]: https://github.com/rotten
[1]: https://github.com/wilsonrmsorg/rethinkdb-multicorn-postgresql-fdw

The wrapper could prove especially useful in cases where a developer wants to
incorporate RethinkDB into an existing application built on PostgreSQL, taking
advantage of RethinkDB features like changefeeds to easily add realtime
updates. You could, for example, use RethinkDB to store and propagate realtime
events while continuing to use PostgreSQL for things like account management
and other data persistence.
<!--more-->

To try the foreign data wrapper myself, I used it to access cat pictures from
my [CatThink demo][] in PostgreSQL.  I built CatThink last year to illustrate
how RethinkDB changefeeds can simplify the architecture of realtime
applications. CatThink, which is built with Node.js and Socket.io, uses
Instagram's realtime APIs and a RethinkDB changefeed to display a stream of the
latest cat pictures posted to the popular photo sharing service.

[CatThink demo]: {% post_url 2014-11-05-cats-of-instagram %}

As I will show you in this article, I used the foreign data wrapper to connect
a PostgreSQL instance to a RethinkDB database so that I could retrieve cat
picture URLs with simple SQL queries.

# Configure the foreign data wrapper

Rick's RethinkDB wrapper is built with [Multicorn][], a PostgreSQL extension
that lets developers implement foreign data wrappers in Python. Using Multicorn
made it possible to build the wrapper around the official RethinkDB Python
driver. The wrapper is currently a read-only implementation&mdash;you can
perform queries that retrieve data from the RethinkDB tables, but you can't
manipulate the wrapped tables with operations like `INSERT` or `UPDATE`.

[Multicorn]: http://multicorn.org/

I performed my experiment on a Linux system running Ubuntu 14.10, RethinkDB
1.15, and PostgreSQL 9.4. I installed the following packages with APT:

```
apt-get install python-setuptools python-dev postgresql-server-dev-9.4 pgxnclient postgresql rethinkdb git python-pip
```

To install Multicorn and the RethinkDB foreign data wrapper, I followed the
instructions from the project's [documentation][].

[documentation]: https://github.com/wilsonrmsorg/rethinkdb-multicorn-postgresql-fdw/blob/master/README.md

# Retrieve RethinkDB data with SQL queries

I used the following command to initialize the foreign data wrapper, specifying
the name of the desired database and the host and port of the RethinkDB server:

```
CREATE SERVER rethink FOREIGN DATA WRAPPER multicorn OPTIONS (wrapper 'rethinkdb_fdw.rethinkdb_fdw.RethinkDBFDW', host 'localhost', port '28015', database 'cats');
```

I used the following SQL expression to expose the `instacat` table, which
contains image posting data from Instagram:

```
CREATE FOREIGN TABLE instacat (id varchar, "user" json, caption json, images json, time timestamp) server rethink options (table_name 'instacat');
```

In the command, I defined columns that correspond with top-level properties
from the documents in the `instacat` RethinkDB table. I can use those columns
when performing a query against the foreign table. Each column in the table is
defined with an associated type. I use the `json` type for properties that
contain objects with other nested values. Note that I string-escaped the `user`
column so that it won't be mistaken for a keyword. I only created columns for a
subset of the properties available in each record. You can create columns for
as many records as you want.

To see the foreign table in action, I performed a simple `select` query in the SQL console:

```
SELECT * FROM instacat;
```

The operation worked as expected, displaying the values from the RethinkDB
table. It's also possible to extract individual sub-properties from the JSON
objects. PostgreSQL 9.3 introduced a number of [specialized SQL operators][2]
for working with JSON data. The following query shows how to extract a few
individual values out of nested JSON structures in each record from the table:

[2]: http://www.postgresql.org/docs/9.3/static/functions-json.html

```
select "user"->'full_name', caption->'text', images#>'{low_resolution,url}' from instacat;
```

The `->` operator allows you to extract the value of a given field as text. The
`#>` operator lets you specify multiple keys so that you can retrieve a value
from an arbitrary depth within a nested JSON structure. The expression
`images#>'{low_resolution, url}'` in PostgreSQL is equivalent to something like
`r.row("images")("low_resolution")("url")` in ReQL. Thanks to the magic of
foreign data wrappers, I can now access kitties in my PostgreSQL applications.

Although you can't modify the data, many SQL operations will work as expected.
You can even use joins, performing queries that operate across foreign tables
and conventional PostgreSQL tables.

# Final notes

Given that every query against a foreign table entails a query against the
RethinkDB instance through the Python driver, there's a fair amount of overhead
involved. The wrapper's documentation recommends using a [materialized view][3]
in performance-sensitive usage scenarios.

[3]: http://michael.otacoo.com/postgresql-2/postgres-9-3-feature-highlight-materialized-views/

The documentation also suggests setting `log_min_messages` to `debug1` in your
postgresql.conf file (`/etc/postgresql/9.4/main/postgresql.conf` on Ubuntu)
during troubleshooting. That will expose errors from the foreign data wrapper
in your logs, which make it a bit easier to see what's going on.

Rick's foreign data wrapper makes it easy to incorporate RethinkDB into
existing applications built on PostgreSQL. It's also a pretty compelling
example of how Multicorn simplifies interoperability between PostgreSQL and
external data sources.

Want to try it yourself? [Install RethinkDB][install] and check out the
[thirty-second quick start guide][guide].

[install]: /docs/install
[guide]: /docs/quickstart

**Resources:**

* [RethinkDB foreign data wrapper][4] for PostgreSQL
* PostgreSQL [JSON operators][5]
* [Multicorn][] PostgreSQL extension

[4]: https://github.com/wilsonrmsorg/rethinkdb-multicorn-postgresql-fdw
[5]: http://www.postgresql.org/docs/9.3/static/functions-json.html
[Multicorn]: http://multicorn.org/
