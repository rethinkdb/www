---
layout: post
title: "Technical update: keep the ball rolling"
author: Gábor Boros
author_github: gabor-boros
---

As you may have noticed in our [previous blog post](https://rethinkdb.com/blog/community-update-stayin-alive), we did not cover every technical detail of what is going on around RethinkDB. Also mentioned earlier in a GitHub [issue](https://github.com/rethinkdb/rethinkdb/issues/6747), communication was not our strength with regard to the future of the project, and we promised this would change. In keeping our word, here is a summary of what’s been going on the last few months and what’s in store.

## Database related changes

Before we discuss the changes we made and what’s next, we need to clarify what our goals are and the current difficulties we face.

<!--more-->

### Official drivers

Right now, the rethinkdb repository contains all the previously supported official drivers. On the one hand, it was good to keep the drivers and database in the same place, because it allowed us to:

* reduce duplicate code
* run integration tests even for older commits
* release the drivers together with the database

On the other hand, it is harder to keep best practices for Python, Ruby, Java, Javascript, and, of course, C++ within the same repository. Simplicity and maintainability was the main idea when we forked RethinkDB as RebirthDB and extracted all the drivers from the rethinkdb repository. Since then, we merged back, but the extracted repositories remained and live together with the non-extracted ones, which still brings in some open-ended questions.

Our plan, until v2.4 is released, is to keep drivers in the same repository as before and port the changes back. Once the new version is released, we plan to finish the extraction and answer those questions like "how to test specific database release with a specific driver version".

### Building RethinkDB

Since we lost the ability to build RethinkDB with [Thanos](https://thanos.atnnn.com/project/rethinkdb), we had to find a solution to be able to do continuous builds and releases. For this purpose, [Sam Hughes](https://github.com/srh) created a [solution](https://github.com/srh/rethinkdb-package-builder) to build packages for main Linux distributions, namely: Debian, Ubuntu, and CentOS. More build targets will come in the future along with the Docker image, which is discussed [here](https://github.com/rethinkdb/rethinkdb/issues/6772). It’s worth it to mention that we have built a [DigitalOcean Marketplace image](https://marketplace.digitalocean.com/apps/rethinkdb) as well, which will be integrated into the pipeline discussed above. With the solution Sam created, everyone can compile his RethinkDB package for a specific commit or tag by parameterizing its setup script.

As you may have noticed, the Windows release was not mentioned in the list above. The reason for this is that we have no capacity at the moment to build for Windows, though we are not saying that we will not accept contributions to support that release in the future.

## Other changes

We made a lot of changes in the background, which may or may not be transparent on a daily basis.

### Credentials

During the years, people came and went and resulted in most of our credentials and access to third-party services being lost. Together with [Christina Keelan Cottrell](https://github.com/KittyBot), we were able to recover these credentials with success. As a result, we can:

* deploy our website again
* manage Slack again
* access Pypi to upload Python client releases
* use JFrog’s BinTray to rerelease new Java drivers in the future
* access DNSimple to change our domain settings

And a lot more. All of this allowed us to move the download and update servers to DigitalOcean, of which the certificate was [expired](https://github.com/rethinkdb/rethinkdb/issues/6764).

There are still some credentials we have yet to recover, but we are continuously working to get the credentials back and create a secret store for them to prevent similar situations.

### Website and documentation

As mentioned earlier, we were able to redeploy the site. To achieve this, besides moving to Netlify, we had to make sure that all dependencies of www and docs repositories are updated. Unfortunately, this introduced some smaller issues, like Javascript errors, which have since been fixed. Although we did our best, if you find a bug, please create a GitHub issue for us or feel free to submit a pull request.

### Misc

Also, we set up static code analysis for some of the repositories (this will be continued), released new client versions, and fixed the enormous amount of bugs.

## Get involved

Most of you asked us about the current status of the project. From a technical point of view, the project is still maintained, though we need maintainers and volunteers who help the community through the journey of this formation. We will also announce a formal fundraiser in the near future and are actively looking for corporate sponsors.

Find us on [Slack](http://slack.rethinkdb.com/), [Discord](https://discord.gg/kaQDYB4), [Twitter](https://twitter.com/rethinkdb), or Freenode (#rethinkdb).
