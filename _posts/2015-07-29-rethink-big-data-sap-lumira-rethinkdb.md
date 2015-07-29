---
layout: post
title: "Rethink your Big Data with SAP Lumira and RethinkDB"
author: Shankar Narayanan
author_github: sgsshankar
hero_image: 2015-07-15-forbidden-planet-beta-banner.jpg
---

***This post is cross-posted from the SAP Community Network Lumira Blog***

Big data has been the buzz all around; more
applications are being built on top of big
data platforms and the whole paradigm shift
moves towards NoSQL databases from
traditional RDBMS. As these databases start
to store transactional and historical data
there is a greater need for reporting. SAP
Lumira is a handy tool as it focuses on big
data and is continuously improving
capabilities in handling big data workloads.

With SAP Lumira 1.27, better integration is
made with platforms like Hadoop.  In this
post, we will describe how to connect SAP
Lumira to another growing NoSQL database
called RethinkDB using a Custom Data Access
Extension.

##RethinkDB

RethinkDB is fairly new and constantly
improving, with features like realtime
changefeeds, easy to setup clusters and an
improved ReQL language. The ability to pull
JSON data directly from the web makes
RethinkDB an ideal choice for next generation
web applications.

In the first step to demonstrate the Custom
Data Access Extension, we will import example
“Election Analysis” data from their website.
The JSON data is imported into RethinkDB into
the test database (you can refer the tutorial
http://www.rethinkdb.com/docs/tutorials/elections/
 to do the same). The Custom Data Access
 extension that I have built to connect to
 RethinkDB is installed in SAP Lumira now.

##Getting data from RethinkDB

The SAP Lumira RethinkDB extension appears
under the External Datasource in the Dataset
Pane in SAP Lumira. Select the Rethink
External Data source and click next to
continue.

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-1.png)

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-2.png)

A new window appears asking information
about the RethinkDB instances to connect and
fetch the data. Enter the following
information:

* The host where Rethinkdb is installed
* The driver port running (leaving blank defaults to port 28015)
* A DB to connect to (leaving blank lists all the db that is present in the instance)
* Your authkey

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-3.png)

Since I left the DB field blank, it displays
a list of all databases on the RethinkDB
instance. Select the desired database and
click OK. In this case, I am selecting
‘test’ as that is where the example data is
loaded.

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-8.png)

The next screen shows a list of tables.
Select the table you have imported the
election data into and click "OK". Here, I
am selecting ‘polls’ that contains the
cleansed data from the example mentioned
earlier.

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-9.png)

Here you can see a preview of what is going to be imported. Click "Create" to import the data.

![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-4.png)

You can manipulate this data like any other regular data in the prepare tab in SAP Lumira. You can also import another table by following the above steps and merging them in SAP Lumira.

##Just a Visual

The visualization below was made using the example data. You can refer to the example link above for information about the data.

Top five states by polls
![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-5.png)

Republican ratings by state
![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-6.png)

Heat map of top ten Democrats
![](/assets/images/posts/2015-07-29-rethink-big-data-sap-lumira-rethinkdb-7.png)

The Custom Data Access Extension is easy to use and you can now do analyses on top of RethinkDB using SAP Lumira. You can download the extension from https://github.com/sgsshankar/lumira-extension-da-rethinkdb

In a future version of Custom Data Access Extension, support for changefeeds, map-reduce capabilities and other RethinkDB query functionalities will be added to support all features of RethinkDB with SAP Lumira.
