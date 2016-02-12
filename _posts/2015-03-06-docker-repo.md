---
layout: post
title: "Docker introduces official RethinkDB repository"
author: Ryan Paul
author_github: segphault
hero_image: 2015-03-06-docker-banner.png
---

Our friends at Docker recently added an [official RethinkDB repository][1] to
the Docker Hub.  They announced the new repo in a [blog post][] yesterday,
highlighting RethinkDB alongside several other prominent open source projects.

[1]: https://registry.hub.docker.com/_/rethinkdb/
[blog post]: https://blog.docker.com/2015/03/thirteen-new-official-repositories-added-in-january-and-february/

Docker is a tool that helps automate deployments. It takes advantage of
platform-level container technology to make it easy to compose isolated
software components in a reproducible way. A growing number of
infrastructure-related tools, ranging from self-hosted PaaS environments to
cluster management systems, are built around the Docker ecosystem.
<!--more-->

You can run the following command to deploy RethinkDB from Docker's official
repository:

```bash
$ docker run -d -P --name rethink1 rethinkdb
```

The images used in the official RethinkDB repository are [maintained][2] by
community member [Stuart Bentley][], who is also responsible for the [RethinkDB
Dokku plugin][] that we [wrote about][3] last year.

[2]: https://github.com/stuartpb/rethinkdb-dockerfiles
[Stuart Bentley]: https://github.com/stuartpb
[RethinkDB Dokku plugin]: https://github.com/stuartpb/dokku-rethinkdb-plugin
[3]: {% post_url 2014-10-23-dokku-deployment %}

After you get a RethinkDB container up and running with Docker, head over to
our handy [ten-minute guide][] to learn how to build applications with
RethinkDB.

[ten-minute guide]: http://rethinkdb.com/docs/guide/javascript/
