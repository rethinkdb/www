---
layout: post
title: "Technical update: keep the ball rolling"
author: Gábor Boros
author_github: gabor-boros
---

As you may be assumed, we did not cover every technical detail of what is going on around RethinkDB in our [previous blog post](https://rethinkdb.com/blog/community-update-stayin-alive). As I mentioned earlier in a GitHub [issue](https://github.com/rethinkdb/rethinkdb/issues/6747), the communication was not our strength with the future of the project, and I promised that this would change. I keep my word, so let me summarize what happened in the last few months and what will come soon.

## Database related changes

Before we discuss what changes we made or what will come, we need to clarify what are the goals that we would like to achieve and what are the current difficulties we are facing.

<!--more-->

### Official drivers

Right now, the rethinkdb repository contains all the previously officially supported drivers. On the one hand, this was good to keep the drivers and database at the same place, because it allowed us to

* reduce duplicated code
* run integration tests even for older commits
* move the drivers together with the database

On the other hand, it is harder to keep best practices for Python, Ruby, Java, Javascript, and, of course, C++ within the same repository. Simplicity and maintainability was the main idea when we forked RethinkDB as RebirthDB and extracted all the drivers from the rethinkdb repository. Since then, we merged back, but the extracted repositories remained and lived together with the non-extracted ones, which still brings in some open-ended questions.

Our plan until v2.4 is released to keep drivers in the same repository as before and port the changes back. Once the new version is released, we are planning to finish the extraction and answer those questions like “how to test specific database release with a specific driver version.”

### Building RethinkDB

Since we lost the ability to build RethinkDB with [Thanos](https://thanos.atnnn.com/project/rethinkdb), we had to find a solution to be able to do continuous builds and releases. For this purpose, [Sam Hughes](https://github.com/srh) created a [solution](https://github.com/srh/rethinkdb-package-builder) to build packages for main Linux distributions, namely: Debian, Ubuntu, and Centos. More build targets will come in the future along with the Docker image, which is discussed [here](https://github.com/rethinkdb/rethinkdb/issues/6772). It worth to mention that we have built a [DigitalOcean Marketplace image](https://marketplace.digitalocean.com/apps/rethinkdb) as well, which will be integrated into the pipeline discussed above. With the solution Sam created, everyone can compile his RethinkDB package for a specific commit or tag by parameterizing its setup script.

As you may notice, the Windows release did not mention in the listing above. The reason for this is that we have no capacity at the moment to build for Windows, though we are not saying that we will not accept contributions to support that release.

## Other changes

We did a lot of changes in the background, which may or may not be transparent on a daily bases.

### Credentials

During the years, people came and went and resulted in most of our credentials and access to third-party services were lost. Together with Christina Keelan Cottrell, we worked a lot to recover these credentials with success. As a result, we can

* deploy our website again
* manage Slack again
* access Pypi to upload Python client releases
* use JFrog’s BinTray to rerelease new Java drivers in the future
* access DNSimple to change our domain settings

And a lot more. If this is not enough, this allowed us to move the download and update servers to DigitalOcean, which certificate [expired](https://github.com/rethinkdb/rethinkdb/issues/6764).

### Website and documentation

As mentioned earlier, we were able to redeploy the site. To achieve this, besides moving to Netlify, we had to make sure that all dependencies of www and docs repositories are updated. Unfortunately, this introduced some smaller issues, like Javascript errors which were fixed since then. Although we did our best, if you find a bug, please create a GitHub issue for us or feel free to submit a pull request.

### Misc

Also, we set up static code analysis for some of the repositories (this will be continued), released new client versions, and fixed the enormous amount of bugs.

## Get involved

Most of you asked us about the current status of the project. From a technical point of view, the project is still maintained, though we need maintainers and volunteers who help the community through the journey of this formation.

Find us on [Slack](http://slack.rethinkdb.com/), [Discord](https://discord.gg/kaQDYB4), [Twitter](https://twitter.com/rethinkdb), or Freenode (#rethinkdb).
