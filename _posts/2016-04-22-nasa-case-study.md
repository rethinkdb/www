---
layout: post
title: "One small step for the Thinker: A case study of RethinkDB at NASA"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image: 2016-04-22-nasa-case-study.png
---

Whenever we hear about another organization using RethinkDB, we always get
incredibly excited. So when we first heard that NASA was using RethinkDB we were
over the moon. We asked Collin Estes, Director of Software Engineering, how
they use RethinkDB at NASA and we are proud to present this case-study
of their usage of RethinkDB below:

---

## RethinkDB Case Study:  NASA (EVA)

**Background:**

Within NASA, the EVA office is responsible for everything dealing with Extra-Vehicular Activity (EVA), commonly referred to a spacewalks.  This includes the Extra-Vehicular Mobility Unit (EMU) which supports activities surrounding the International Space Station. The engineering, processing, logistics and operation of the EMU spacesuit is contracted under the “EVA Space Operations Contract” (ESOC) to United Technologies Aerospace Systems and their sub-contract partners, including MRI Technologies.  Part of MRI’s role on the ESOC contract is the software development supporting the property management, hardware processing, logistics, hardware operations and other business activities required to support the ESOC contractor community, EVA Office and the International Space Station program.  The ESOC contract has over 20 years of spacesuit data residing in numerous custom built applications in a wide variety of technology stacks.


**Data Integration:**

In 2015, the EVA Office created a project tasked with the broad goal of better data integration across both government and contractor systems.  With support from NASA’s Office of the Chief Information Office (OCIO) and led by NASA’s Chief Architect, Sandeep Shetye, the MRI Dev Team designed and implemented a completely open source, cloud-based, enterprise architecture to begin the process of integrating over three decades of spacesuit data and migrating data and application functionalities to open source solutions hosted in the  AWS GovCloud.  

The MRI dev team solution centered around containerization of microservices with Docker, web APIs built with Node.js, and RethinkDB.  Today the MRI dev team is extracting and transforming data from legacy relational database systems (MSSQL and Oracle DB) and loading to RethinkDB.  RethinkDB is also the database being used for all new application development, as well as new application interfaces aimed at replacing existing legacy applications on the ESOC contract.  

**RethinkDB and ESOC**

RethinkDB was chosen for several reasons to meet the basic requirement of a document based No-SQL database.  A critical aspect of the migration of applications and data to new infrastructure is that day to day business activities of the ESOC contract must proceed as normal, and implementation of new applications must be done on a zero interference basis.  To meet this requirement MRI developed a synchronization strategy that would allow new applications to be built with Node.js/RethinkDB while also synchronizing data between RethinkDB and legacy database systems so business units could run parallel operations in new and existing applications without duplication of responsibility of the user community in maintaining data in separate systems.  As business units migrate to the newly created applications, these synchronization tasks are depreciated and legacy systems decommissioned.  This strategy was primarily designed around RethinkDB change events and recurring ETL services from legacy systems.  New applications are built for real-time first, also making RethinkDB a powerful tool in this new stack, radically simplifying real-time services in support of Extra-Vehicular Activity.

On ESOC, the MRI Dev Team’s vision is real-time services and applications, with complete data integration; in support of all activities surrounding the EMU. From the engineering and fabrication of the components and tools, processing and logistics of flight manifesting and planning, usage and hardware life tracking on the ISS, telemetry data visualizations during spacewalks. From ground to orbit and back, and everything in-between.  Reducing operations and maintenance costs, helping to build and operate safer spacesuits, and providing the access to data and infrastructure that will help us take astronauts to Mars and beyond.

The MRI Dev Team

Collin Estes<br>
*Director of Software Engineering, Chief Architect*

Mike Fielden<br>
*Technical Lead*

Shawn McGinty<br>
*Senior Software Engineer*

Ryan Gill<br>
*Software Engineer*

---

From all of us at RethinkDB, we want to thank Collin and his team for putting together this case study for us and sharing how they use RethinkDB.

* Ready for lift-off? Try out our [ten-minute guide][10m] to RethinkDB.
* Take a peek at our [Changefeeds API][changefeeds] mentioned in the case study.
* Check out other companies that use RethinkDB in our [Realtime Stories][realtime-stories].

[10m]: https://rethinkdb.com/docs/guide/javascript/
[changefeeds]: https://rethinkdb.com/docs/changefeeds/python/
[realtime-stories]: https://www.youtube.com/playlist?list=PLeOf6NJfdgGOxIXNjShlShNgshy4AXr91
