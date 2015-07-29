---
layout: post
title: "Rethink your Big Data with SAP Lumira and RethinkDB"
author: Shankar Narayanan
author_github: sgsshankar
hero_image: 2015-07-15-forbidden-planet-beta-banner.jpg
---

***This post is cross posted from the SAP Community Network Lumira Blog***

Big data has been the Buzz all around; more applications are being built on top of Big data platform and the whole paradigm shift takes a move towards NoSQL Databases from traditional RDBMS. When these databases start to hold transactional and historical data, there is a need for reporting. SAP Lumira comes as a handy tool as it focuses on Big data and is continuously improving capabilities in handling them.

SAP Lumira 1.27 brought in better integration with Big data like Hadoop. You can refer to my blogs on how to connect your SAP Lumira to MongoDB here: http://scn.sap.com/community/lumira/blog/2014/06/17/connecting-sap-lumira-with-mongodb--part-1 and http://scn.sap.com/community/lumira/blog/2014/06/17/connecting-sap-lumira-with-mongodb--part-2. In this blog, we will describe how to connect SAP Lumira to another growing NoSQL database called RethinkDB using Custom Data Access Extension.

RethinkDB :

RethinkDB is fairly new and improving, with features like Real time notification, easy to setup clusters and improved ReQL language. The ability to pull JSON data directly from web makes RethinkDB an ideal choice for next generation web applications.
As a step to demonstrate the Custom Data Access Extension, we will import example data “Election Analysis” from their website. The JSON data is imported into RethinkDB into the test database (you can refer the tutorial http://www.rethinkdb.com/docs/tutorials/elections/ to do the same). The Custom Data Access extension that I had built to connect to RethinkDB is installed in SAP Lumira now. Find more about how to configure your SAP Lumira for Data Access Extension and how to build one at Lumira - Open Source Data Access Extensions

Getting data from RethinkDB

RethinkDB Extension appears under the External Datasource in the Dataset Pane in SAP Lumira. Select the Rethink External Data source and click next to progress.

Getting data from RethinkDB in SAP Lumira

External Datasource in SAP Lumira

A new window appears asking information about the RethinkDB instances to connect and fetch the data. Enter the following information:
host where Rethinkdb is installed
port on which it’s running (leaving blank defaults to port 28015)
db to connect to (leaving blank lists all the db that is present in the instance)
authkey

RethinkDB Data Access Extension

Since I left db as blank, it shows me list of all databases in the system. Select the required database and click Ok. In this case, I am selecting ‘test’ as that is where the example data is loaded.

RethinkDB Data Access Extension_select db

The next screen shows list of tables. Select the required table and click Ok. Here, I am selecting ‘polls’ that contains the cleansed data from the example imported.

RethinkDB Data Access Extension_select table

You get the data set preview of what is going to be imported. Click Create to import the data.

New dataset from RethinkDB in SAP Lumira

You can manipulate this data like any other regular data in the prepare tab in SAP Lumira. You can also import another table by following the above steps and merging them in SAP Lumira.

Just a Visual

The visualization below was made using the example data. You can refer to the example link above for information about the data.

Top 5 states by poll
RethinkDB_SAP Lumira_Visualization1

Gross Operating Profit for each state
RethinkDB_SAP Lumira_Visualization2

Top 10 Democrats
RethinkDB_SAP Lumira_Visualization3

The Custom Data Access Extension is easy to use and you can now do analysis on top of RethinkDB using SAP Lumira. You can download the extension from https://github.com/sgsshankar/lumira-extension-da-rethinkdb

In the future version of Custom Data Access Extension, support for live steaming, map reduce capabilities and other rethinkDB query functionalities would be added to extend the full potential of RethinkDB to Visualize on SAP Lumira.
