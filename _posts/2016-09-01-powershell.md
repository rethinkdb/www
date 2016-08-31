---
layout: post
title: "Use the RethinkDB C# driver in PowerShell on Linux"
author: Ryan Paul
author_github: segphault
---

PowerShell is a scripting and command line shell built on top of the .NET
runtime. Although it was originally created for Windows, Microsoft recently
introduced an open source version of PowerShell powered by the cross-platform
compatible .NET Core. Users can now download and run PowerShell on Linux and Mac
OS X.

One of PowerShell's strengths is its interoperability with the .NET ecosystem.
PowerShell can load types and methods from .NET assemblies, making it possible
for PowerShell scripts to incorporate functionality that is implemented in
practically any C# library. That capability also makes PowerShell a great
environment for interactively exploring C# APIs.

When Microsoft announced the availability of PowerShell on Linux earlier this
month, I tried it out in a Docker container on my home Ubuntu server. As an
experiment, I had it load up the [C# RethinkDB driver][] developed by
[Brian Chavez][]. Using the driver, I was able to instantiate a RethinkDB
database connection and perform queries from the comfortable confines of the
interactive PowerShell command line environment.

<!--more-->

# Initial Setup

The PowerShell open source project [provides binaries][releases] for several
platforms. Their binaries conveniently bundle a complete .NET Core stack so that
you don't have to install a lot of additional dependencies. I followed their
[Ubuntu installation instructions][ubuntu-install] and used their provided DEB
package.

I downloaded a zip archive with the [latest release][] of Brian's RethinkDB
client library from GitHub and extracted its contents into my home directory.
The zip archive includes compiled assemblies for several different .NET
environments. The `dnx_build/netstandard1.3` directory has DLLs that are
compatible with the .NET Core environment that comes bundled with the PowerShell
binaries on Linux. In addition to the RethinkDB.Driver assembly, I also needed
`Microsoft.Extensions.Logging.Abstractions`, which I
[grabbed from NuGet][logging].

# Using the RethinkDB driver in PowerShell

At the PowerShell command line, I used the `Add-Type` command to load the
assemblies:

```powershell
PS> Add-Type -Path ./lib/netstandard1.1/Microsoft.Extensions.Logging.Abstractions.dll
PS> Add-Type -Path ./RethinkDb.Driver/dnx_build/netstandard1.3/RethinkDb.Driver.dll
```

To [access a static class][] in PowerShell, you enclose the name in square
brackets. After loading the `RethinkDB.Driver` DLL, I was able to use the
bracket notation to access the RethinkDB driver's top-level class and its `R`
singleton. I assigned it to a variable for convenience:

```powershell
PS> $R = [RethinkDB.Driver.RethinkDB]::R
```

Next, I used the `R.Connection` method to create a database connection that I
could use for queries. You can optionally use the `Hostname` and `Port` methods
to specify where the client library should look for the database server:

```powershell
PS> $conn = $R.Connection().Hostname("localhost").Connect()
```

To perform a query, you can write a ReQL expression and run it on the saved
connection instance. The following is a simple example that generates a random
number within a range, adds five to the generated number, and then displays the
returned result.

```powershell
PS> $R.Random(1, 10).Add(5).Run($conn)
13
```

In my RethinkDB database, I have a table called `fellowship` that contains the
nine members of Tolkien's Fellowship of the Ring. Each document contains a
`name` property that contains the name of the individual member. The following
query fetches all of the documents in the table and displays the names:

```powershell
PS> $R.Table("fellowship")["name"].Run($conn)
Gandalf
Aragorn
Sam
Pippin
Gimili
Merry
Boromir
Legolas
Frodo
```

To display the contents of the table in PowerShell's signature column format, I
have the query output a raw JSON string that I can pipe into PowerShell's
`ConvertFrom-Json` command.

```powershell
PS> $R.Db("test").Table("fellowship").CoerceTo("array").Run($conn).ToString() | ConvertFrom-Json

id                                   name    species
--                                   ----    -------
1b4a665c-4063-41da-af93-d761696de6ef Gandalf istari
6b66adf3-f7dc-4a3e-8b99-2729b1b146a4 Gimili  dwarf  
3b569c3d-573a-45ce-99a6-fb973de41c22 Aragorn human  
df504a52-433c-4d1b-bb11-6b1a8af13ce4 Frodo   hobbit
15e726c9-7255-44de-913d-188dd3e52cbb Sam     hobbit
62e732ea-ec4c-47c4-a23a-9f38103da6e3 Merry   hobbit
a11d4612-c031-423d-ab1c-9026687b7bd2 Boromir human  
d5ad62ed-6b24-4018-b523-8bb966b87026 Legolas elf    
253f2be1-c964-4d2f-8e76-af72ecf54edb Pippin  hobbit
```


I tested filtering, record insertion, and a few other common ReQL operations.
Most of the client library's API surface works as expected in PowerShell.
PowerShell's `@{}` notation for describing object literals is useful for
inserting new database records and filtering:

```powershell
PS> $R.table("fellowship").filter(@{"species" = "hobbit"})["name"].Run($conn)
Frodo
Sam
Pippin
Merry

> $R.table("fellowship").insert(@{"name" = "Somebody"; "species" = "Whatever"}).Run($conn).toString()

{
  "deleted": 0,
  "errors": 0,
  "generated_keys": [
    "3f579ca5-c921-483c-9ce7-4c06b2228aa0"
  ],
  "inserted": 1,
  "replaced": 0,
  "skipped": 0,
  "unchanged": 0
}
```

# Changefeeds in PowerShell

RethinkDB [changefeeds][] make it possible to build applications that react to
changes in the database. The RethinkDB driver's `Changes` method, which attaches
a changefeed to a query, works largely as expected inside of PowerShell:

```powershell
PS> $R.Db("rethinkdb").Table("stats").Changes().Run($conn) | foreach {Write-Host $_.toString()}

{
  "new_val": {
    "id": [
      "cluster"
    ],
    "query_engine": {
      "client_connections": 10,
      "clients_active": 6,
      "queries_per_sec": 0.640447762,
      "read_docs_per_sec": 0,
      "written_docs_per_sec": 0
...
```

The changefeed query runs synchronously, which means that the PowerShell
environment runs it in the foreground until the user hits `ctrl-c` to terminate
the command.

# Next steps

Passing the output of ReQL database queries into local PowerShell commands could
be really useful for automated scripting and interactive data exploration. You
can [install RethinkDB][] if you'd like to try out the examples in this blog
post yourself.

**Resources**:

* [PowerShell][] project on GitHub
* [C# RethinkDB Driver][] on GitHub


[Brian Chavez]: https://github.com/bchavez
[C# RethinkDB Driver]: https://github.com/bchavez/RethinkDb.Driver
[ubuntu-install]: https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md#ubuntu-1604
[releases]: https://github.com/PowerShell/PowerShell/releases
[latest release]: https://github.com/bchavez/RethinkDb.Driver/releases
[logging]: https://www.nuget.org/packages/Microsoft.Extensions.Logging.Abstractions/
[access a static class]: https://msdn.microsoft.com/en-us/powershell/scripting/getting-started/cookbooks/using-static-classes-and-methods
[changefeeds]: /docs/changefeeds/
[install RethinkDB]: /docs/install/windows/
[PowerShell]: https://github.com/PowerShell/PowerShell

