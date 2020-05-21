# Download Server Changes

We are continuously working to improve our infrastructure and make it easier for you to use RethinkDB. Today, we would like to announce the replacement of the download server. This change will affect every Docker image, Virtual Machines, and every platform, so please stay with us and **read this post carefully**. The download server will be at the same location ( [https://download.rethinkdb.com](https://download.rethinkdb.com/) ), but the repository structure of it will change.

## Changes

Generally speaking, the new repository schema will look like `https://download.rethinkdb.com/repository/<DISTRIBUTION>/`, where `<DISTRIBUTION>` can be `centos`, `ubuntu-bionic`, `raw` and so on. Below you can find the changes for every distribution we currently support.

### APT repositories

To install RethinkDB from an APT repository, you will need to run the following:

```bash
$ apt-key adv —keyserver keys.gnupg.net —recv-keys “539A 3A8C 6692 E6E3 F69B 3FE8 1D85 E93F 801B B43F”
$ echo “deb https://download.rethinkdb.com/repository/$APT_REPOSITORY $DISTRIBUTION_NAME main” > /etc/apt/sources.list.d/rethinkdb.list
$ sudo apt-get update
$ sudo apt-get install rethinkdb
```

Compared to the previous installation method, the only change is in line 2. You will need to write `deb https://download.rethinkdb.com/repository/$APT_REPOSITORY $DISTRIBUTION_NAME main` instead of `deb https://download.rethinkdb.com/apt $DISTRIBUTION_NAME main`. 
As an example, it would look like the following for ubuntu-focal:

```bash
$ apt-key adv —keyserver keys.gnupg.net —recv-keys “539A 3A8C 6692 E6E3 F69B 3FE8 1D85 E93F 801B B43F”
$ echo “deb https://download.rethinkdb.com/repository/ubuntu-focal focal main” > /etc/apt/sources.list.d/rethinkdb.list
$ sudo apt-get update
$ sudo apt-get install rethinkdb
```

Easy-peasy lemon squeezy.

**Debian**

```
https://download.rethinkdb.com/repository/debian-buster/
https://download.rethinkdb.com/repository/debian-jessie/
https://download.rethinkdb.com/repository/debian-stretch/
```

**Ubuntu**

```
https://download.rethinkdb.com/repository/ubuntu-bionic/
https://download.rethinkdb.com/repository/ubuntu-disco/
https://download.rethinkdb.com/repository/ubuntu-eoan/
https://download.rethinkdb.com/repository/ubuntu-focal/
https://download.rethinkdb.com/repository/ubuntu-trusty/
https://download.rethinkdb.com/repository/ubuntu-xenial/
```

### Yum repositories

In case of yum repositories this change is more easier than for apt ones. We will need to use a new repo config for rethinkdb package, enable GPG check and add the GPG public key file location. These changes should be done to increase security.
So a complete example would look like this:

```bash
$ cat << EOF > /etc/yum.repos.d/rethinkdb.repo
[rethinkdb]
name=RethinkDB
enabled=1
baseurl=https://download.rethinkdb.com/repository/centos/8/x86_64/
gpgkey=https://download.rethinkdb.com/repository/raw/pubkey.gpg
gpgcheck=1
EOF

$ sudo yum update && yum install rethinkdb
```

**CentOS/RHEL**

```
https://download.rethinkdb.com/repository/centos/6/
https://download.rethinkdb.com/repository/centos/7/
https://download.rethinkdb.com/repository/centos/8/

```

### Other releases

For other releases such as macOS, Windows source distributions and custom releases, we created a common repository, `https://download.rethinkdb.com/repository/raw/`.

## Rollout

The changes mentioned above will be rolled out at **May 29 06:00 UTC**. This means that the download server will not be available for a short time, and existing integrations depending on the download server must be changed.

Since it is a relatively big change, which can break lot of installations, we would like to help you in case of any question. Feel free to reach me out on Slack (@boros) or Discord (@gabor-boros#5245) anytime and I can help answering all your questions.

We will make sure that other distributions like homebrew or docker packages will be updated too, so you won't encounter any inconveniences.

## Get involved

As an open-source project that is developed and  [financially supported](https://funding.communitybridge.org/projects/rethinkdb)  by its users, RethinkDB welcomes your participation. If there’s a feature or improvement that you would like to see, you can help us make it a reality. If you’d like to join us, there are many ways that you can get involved.
Learn  [how to contribute](https://rethinkdb.com/contribute)  to RethinkDB and find us on  [Slack](http://slack.rethinkdb.com/) ,  [Discord](http://discord.rethinkdb.com/) ,  [Twitter](https://twitter.com/rethinkdb) , or Freenode (#rethinkdb).
