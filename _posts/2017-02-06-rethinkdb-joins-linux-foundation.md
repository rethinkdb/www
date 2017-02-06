---
layout: post
title: "RethinkDB joins The Linux Foundation"
author: Michael Glukhovsky
author_github: mglukhovsky
hero_image: 2017-02-06-linux-foundation.png
---

When the company behind RethinkDB shut down last year, a group of former employees and members of the community formed an interim leadership team and began devising a plan to perpetuate the RethinkDB open-source software project by transitioning it to a community-driven endeavor. Today's announcement by the [Cloud Native Computing Foundation](https://www.cncf.io/) (CNCF) marks the culmination of that effort. The CNCF purchased the rights to the RethinkDB source code and contributed it to [The Linux Foundation](https://www.linuxfoundation.org/) under the permissive [ASLv2 license](https://www.apache.org/licenses/LICENSE-2.0).

RethinkDB is alive and well: active development can continue without disruption. Users can continue to run RethinkDB in production with the expectation that it will receive updates. The website, GitHub organization, and social media accounts will also continue operating. The interim leadership team will work with the community to establish formal governance for the project. Under the aegis of The Linux Foundation, the project has strong institutional support and the capacity to accept donations.

Over the past several months, members of the community have expressed interest in making donations to fund ongoing RethinkDB development. We're now equipped to accept those donations and put the money we raise to good use. [Stripe](https://stripe.com) has generously agreed to match up to $25,000 in donations. You can [donate here](/contribute) to support RethinkDB’s future as an open-source project.

<!--more-->

# What is RethinkDB?

RethinkDB is a distributed, open-source database for building realtime web applications. It has an expressive query language that supports method chaining and distributed joins. The database is easy to scale, with a robust clustering and automatic failover. RethinkDB's signature feature is it’s native support for [live queries](/docs/changefeeds) that push realtime updates to your application.

The company behind RethinkDB [shut down last year](/blog/rethinkdb-shutdown/) after struggling to build a sustainable business around the product. Many former RethinkDB employees currently work for Stripe, where they help build infrastructure for developers around the world. After the company behind RethinkDB closed its doors, the database continued to live on as an open-source software project. Today’s announcement eliminates any remaining uncertainty about the project’s health and status, ensuring a bright future for the project in community hands.

# What happens next?

We’ll be steadily open-sourcing more software, content, a huge amount of artwork (by the wonderful [@annieruygt](https://www.instagram.com/annieruygt/)) and documentation developed by the core team over the past seven years. We’ve also been speaking with the CNCF about possibly becoming an [Inception](https://www.cncf.io/projects/graduation-criteria) project going forward. Our community has some important decisions to make together about how to define RethinkDB’s future.

New RethinkDB releases are already in the works: over the past few months, volunteer contributors have continued working on improvements to the database. In the next few days, you can expect to see the release of RethinkDB 2.4. The new version includes improvements from the community as well as features that were developed by the original RethinkDB team before the company shut down. You can also expect to see a 2.3.6 release with important bug fixes.

On the roadmap, the community has some preliminary plans for version 2.5. Making the code more accessible to new contributors is a high priority. That will involve refactoring to remove technical debt and legacy code or features. The 2.5 release could potentially introduce some performance improvements that boost hard-durability writes.

There is also community momentum around [Horizon](https://horizon.io/), the RethinkDB-powered Node.js backend for building realtime web applications. You can look forward to seeing more details shared on the Horizon blog in the coming weeks.


# Who is involved?

The volunteer interim leadership team is made up of former RethinkDB team members Christina Keelan, Etienne Laurin & Sam Hughes, and community members Marshall Cottrell, Ross Kukulinski, Chris Abrams, and Matt Broadstone. CNCF executive director Dan Kohn, CNCF TOC member Bryan Cantrill and RethinkDB founders Mike Glukhovsky and Slava Akhmechet were also involved in securing the transition. At The Linux Foundation, RethinkDB is in excellent company. The foundation is also responsible for Node.js and the Linux kernel. Its leadership team and roster of corporate members are practically unrivaled in this space.

# What took so long?

When the company shut down, creditors held the source code and other assets of the project. Although it would have been possible to fork the source code and continue developing it with a new name under the terms of the AGPL, the interim leadership team felt that securing the rights and adopting a more permissive license would provide a stronger foundation for moving the project forward. The CNCF graciously stepped up and negotiated to buy the code on behalf of the community.

The sensitive nature of the transaction made it difficult to discuss the specifics with the broader community while negotiations were still underway. The protracted silence was necessary to ensure the successful completion of the deal and provide as much continuity as possible for existing users and contributors. Now that the rights to the code are officially in community hands, the project can move forward without any further distraction.

# Join the RethinkDB community

If you'd like to participate in the project, there are many ways that you can get involved:
  - Learn [how to contribute](/contribute) to RethinkDB
  - Join the #open-rethinkdb channel in the [RethinkDB Slack](http://slack.rethinkdb.com)
  - Submit pull requests and open issues [on GitHub](https://github.com/rethinkdb)
  - Follow [@rethinkdb](https://rethinkdb.com) on Twitter
  - [Get started](/docs/quickstart) with RethinkDB

For more details about the project's status and roadmap, you can refer to the [notes from the January open-rethinkdb meeting](https://docs.google.com/document/d/1cTqKt1_EBanGoVmYyahdLyDD8dhCa0SdD0CbjbP67f8/edit). Stay tuned for more details and keep an eye open for our upcoming releases.
