---
layout: post
title: "How the impressive new networking system in Docker 1.9 improves deployment"
author: Ryan Paul
author_github: segphault
---

Docker containers simplify application deployment, making the process more reproducible and conducive to composability. Docker 1.9, which was [released last week][docker-release], introduces a [new approach to container networking][docker-networking] that has significant implications for users. It provides a more flexible way to connect services between containers, making it easier to manage Docker deployments that have multiple interconnected parts.

If you have, for example, a containerized RethinkDB cluster or even just a single RethinkDB instance that you share with multiple containerized applications on the same host, you can potentially benefit from the new networking features. In this blog post, I'll show you how you can take advantage of Docker 1.9 networking in a single-host development environment like the one that I use at home.

<!--more-->

## Linking: old and busted

Previous versions of Docker relied on a feature called "linking" to connect containers with each other. You would specify a container's links when you created it from the command line--the new container would have access to the network services running on the ports exposed by the linked container. Docker would automatically set up environment variables in the new container to indicate the IP address and port numbers of the exposed services.

For example, when I would create a new container for a Node.js application and link it to my existing RethinkDB container, the container would have an environment variable called `RETHINKDB_PORT_28015_TCP` with the IP address and port number that I'd need to use to connect the RethinkDB client driver in the new container to the RethinkDB instance running in the existing container.

Linking worked reasonably well in practice, but it had a lot of annoying limitations that significantly detracted from Docker's power and usefulness. The biggest problem was that links would break when you removed containers.

Consider a scenario where I want to update my RethinkDB instance so that I'm running the latest version of the database. The best way to do that is to delete the current RethinkDB container and create a new one that uses an updated image. I use volumes to store the actual data, so I can blow away the container whenever I want without any real consequence. But because removing a container causes all the links to break, I would also have to delete and re-create all of the application containers that linked to the database container. That's one of many problems that the new Docker networking system solves for me.

## Networking: the new hotness

In Docker 1.9, linking is deprecated in favor of the new networking system. You can create named networks and attach containers to those networks. Containers can reach services exposed by any other container within the same shared network. Networks are delightfully easy to use and work better in practice than linking. Let's take a quick walk through the steps that you might take to set up a RethinkDB application. Create a network for sharing the RethinkDB database:

```
$ docker network create rethinknet
```

Run a RethinkDB container and use the new `--net` parameter to connect it to the network:

```
$ docker run -it -d --net rethinknet --name rethinkdb-stable
             -P -v $PWD/rethinkdata:/rethinkdb/data
             rethinkdb:latest
```

Run a Node.js application in a container connected to the same network:

```
$ docker run -it -d --net rethinknet --name rethinkdb-app
             -v $PWD/src:/usr/src/app -w /usr/src/app
             node:5 node app.js
```

In the Node.js application, you can use code like this to establish the connection to the database:

```javascript
r.connect({host: "rethinkdb-stable", port: 28015})
```

Even though the RethinkDB container's ports are bound to randomized ports on the host, you can still use the standard 28015 port that is exposed by the container. You can also use the name of the container to reference the host because Docker automatically adds the relevant reference to your container's `/etc/hosts` file--much simpler than the environment variables that you use with container linking.

If you destroy the `rethinkdb-stable` container and it replace it with another that has the same name, it will still be accessible to the application container as long as they are both still attached to the `rethinknet` network. That takes a lot of the pain out of updates and similar tasks that require you to destroy containers.

On my home Docker server, I also have a separate container that runs a custom build of RethinkDB's latest code from the git repository. I have that in the same `rethinknet` network, but I named the container `rethinkdb-dev` so that I can easily switch between the stable and development versions in my projects just by using the desired hostname in the client's `connect` method.

## Further reading

I only looked at single-host scenarios in this blog post, but you can also use Docker's new networking system with more complex multi-host deployments. You can learn more about Docker overlay networks by visiting the [official documentation][overlay-docs]. You can also visit the documentation to learn more about the supported [commands for Docker network management][network-docs].

Want to deploy RethinkDB with Docker? The Docker Hub hosts an [official RethinkDB repository][hub-repo]. After you get a RethinkDB container up and running, head over to our handy [ten-minute guide][10-guide] to learn how to build applications with RethinkDB.

**Resources**:

* [Docker 1.9 release announcement][docker-release]
* [Introduction to Docker 1.9 networking][docker-networking]
* [RethinkDB repository at the Docker Hub][hub-repo]

[docker-release]: https://blog.docker.com/2015/11/docker-1-9-production-ready-swarm-multi-host-networking/
[docker-networking]: http://blog.docker.com/2015/11/docker-multi-host-networking-ga/
[overlay-docs]: https://docs.docker.com/engine/userguide/networking/get-started-overlay/
[network-docs]: https://docs.docker.com/engine/userguide/networking/dockernetworks/
[hub-repo]: https://registry.hub.docker.com/_/rethinkdb/
[10-guide]: http://rethinkdb.com/docs/guide/javascript/

