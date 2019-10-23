---
layout: post
title: "RethinkDB community update: Stayin' alive!"
author: Christina Keelan & Gábor Boros
author_github: rethinkdb
hero_image: rethinkdb-general-blog.png
---

We have some exciting news for you today, but let me begin by expressing our appreciation for you, the RethinkDB community! Your continued support over the past couple of years as we've gotten back on track means so much. We would never have gotten this far without continued engagement from the community. With that in mind, we're pleased to announce that we've completed all the necessary tasks for continued development under the Linux Foundation and fundraising via CommunityBridge.

## Technical updates

Since RethinkDB merged back from the fork, we’ve put a lot of effort into cleaning up and reorganizing the project. We have access to [PyPi](https://pypi.org/project/rethinkdb/), to the infrastructure, and most of the official RethinkDB accounts.

We set up static code analysis for some of the repositories (this will be continued), released new client versions, fixed the enormous amount of bugs and released a [2.4.0-beta for DigitalOcean](https://marketplace.digitalocean.com/apps/rethinkdb) Marketplace, redeployed and moved the website and documentation site to Netlify, set up a new [download server](https://download.rethinkdb.com/) on DigitalOcean and our next step will be to create the CI/CD infrastructure.
<!--more-->

## What’s next

_Technical_

The next biggest change will be the CI/CD infrastructure for RethinkDB which will allow us to deploy RethinkDB version 2.4.

_CommunityBridge_

We’re happy to share that we are now hosting our fundraising through CommunityBridge, a crowdsourcing platform from Linux Foundation for open source projects. Learn more about [CommunityBridge](https://communitybridge.org/) and check out the fundraising page [here](https://funding.communitybridge.org/projects/rethinkdb). We’ll share more about fundraising and finances in a future post.

_Volunteers_

We will need volunteers to help revisit the website’s content, check client and database documentation, create new examples of how to use RethinkDB, client development, database development, and evangelization. If you would like to help with any of the above, please fill out [this form](https://forms.gle/VD5nDtGqSnG5KhHf9). Some projects will be compensated, we will discuss details in another post.

## Get involved

* Slack: Our official Slack group is [active](https://join.slack.com/t/rethinkdb/shared_invite/enQtNzAxOTUzNTk1NzMzLWY5ZTA0OTNmMWJiOWFmOGVhNTUxZjQzODQyZjIzNjgzZjdjZDFjNDg1NDY3MjFhYmNhOTY1MDVkNDgzMWZiZWM) again. Please join us for updates, ask for help, and meet other community members.
* Spectrum: This [channel](https://spectrum.chat/rethinkdb) was created in 2018 when we did not have access to Slack. We will shut this group down on November 1st, 2019 as the community reported it is hard to use and conversation has slowed now that [Slack](http://slack.rethinkdb.com) is active again.
* Twitter: We have not been active on [Twitter](https://twitter.com/rethinkdb) recently, but as of this posting, it will be active and monitored again. @rethinkdb or #rethinkdb with questions (which we will RT for the community to answer), blog posts, RethinkDB projects, talks you’re doing, etc.  
* IRC: #rethinkdb on Freenode.

## Thank you!

We honestly could not have gotten back on track if it was not for the persistent support of this community. A few notable thank you’s (please let us know if we need to add anyone to this list):

For help in development

* [Adam Grandquist](https://github.com/grandquista)
* [Etienne Laurin](https://github.com/atnnn)
* [Sagiv Frankel](https://github.com/sagivf)
* [Sam Hughes](https://github.com/srh)

For the community support

* [Alisson Cavalcante Agiani](https://github.com/thelinuxlich)
* [Annie Ruygt](https://github.com/ahruygt)
* [Chris Abrams](https://github.com/chrisabrams)
* [Floyd Kots](https://github.com/floydkots)
* [Christina Keelan Cottrell](https://github.com/kittybot)
* [Marshall Cottrell](https://github.com/marshall007)

And for those companies who continuously support us

* [Atlassian](https://www.atlassian.com/software) - Gave us an OSS license to be able to handle internal tickets like vulnerability issues
* [CNCF](https://www.cncf.io) - Who supports us day by day
* [Digital Ocean](https://www.digitalocean.com/) - Provides us the infrastructure and servers needed for serving mission-critical sites like download.rethinkdb.com or update.rethinkdb.com
* [Netlify](https://www.netlify.com/) - Gave us an OSS license to be able to migrate rethinkdb.com
