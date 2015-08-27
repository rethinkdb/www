---
layout: post
title: "Rethinking temperature, sensors, and Raspberry Pi"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image: 2015-07-31-temperature-sensors-and-a-side-of-pi-hero.png
---

Getting started on your first hardware project can be difficult. Luckily these
days we have things like the [Raspberry Pi][rbpi]. which put almost everything
we need into a nice bundled package to get started on your first cool hardware
project. Even better, the Raspberry Pi runs [Rasbian][rasbian], a variant of
Debian, which makes it pretty familiar with those already comfortable with
popular Linux distributions. The next step is to connect a sensor and it's
definitely easier than you think. But the question always remains, once I'm
collecting my data, where will I store it and how do I easily setup some sort of
notification service? In this post, I'll tell you what you need to do to connect
your first sensor, get RethinkDB going on your Raspberry Pi, and push that data
to all your devices using PushBullet.

<!--more-->
<div style="font-weight: bold; padding-top:10px; padding-bottom:10px; text-align:center; width:100%">
<a href="https://www.youtube.com/watch?v=z5poKPPr4oc">I demo'd this tutorial in a talk I gave at the RethinkDB meetup at HeavyBit<br> which you can watch here.</a></div>

I wasn't sure what I wanted to do for my first hardware project but having a
Raspberry Pi gave me a great place to start. I knew though that if I kept
worrying about voltages and GPIO pins I would never get started. So I took a
leap and went to [Adafruit.com][adafruit] and purchased my first temperature and
humidity sensor. I choose the [AM2302][am2302] because of the support I found on
the Adafruit website and the special Python-wrapped C libraries which Adafruit
had already written and put up on Github.

<img width="100%" style="float:left;" src="http://i.imgur.com/qXcXsA9.gif">

<center style="padding-top:10px;padding-bottom:10px">You too can finish your project this fast!</center>

After my sensor arrived, I realized the three cables coming from the sensor
couldn't be directly connected to the Raspberry Pi as the GPIO pins are just
that, pins. Where somewhere In my mind I had figured they were female
connectors. Not wanting to dive into soldering and burn my fingers or play with
molten metal, I decided that I would much rather ride my bike out to Fry's and
get some [female-female jumper cables][jumper_cables] for a couple bucks.

Getting started working with the GPIO pins is also somewhat challenging. As I
had already lost my Raspberry Pi instructions within the first 30 seconds of
opening the box. Were there any instructions in there anyway? Luckily, the
Internet is fully of documentation on the layout of the GPIO pins for each
version of the Raspberry Pi. My Raspberry Pi 2 being somewhat different than the
previous two. Make sure when wiring up your project that you follow a pinout
guide [such as this one][rbpi_pinout]. Plugging the wires in the wrong places
can render your Raspberry Pi unusable, so check twice and plug once!

For reference, I am using **BCM pin #22** (not _physical_ pin 22!) for the data port in my future examples.

<img width="100%" style="float:left;" src="/assets/images/posts/2015-07-31-temperature-sensors-and-a-side-of-pi-1.png">


# Getting RethinkDB setup on the Raspberry Pi

I wish I could say that this part of the process took unprecedented hacker skill
or intelligence beyond measure on my part, but it's actually a piece of cake.

Following the [directions here][install_rethinkdb] and assuming you have Rasbian
(or other Debian deviant) on your Raspberry Pi you should be good to go. The
process takes a couple hours to compile RethinkDB from source (I'm working on
the .deb package for ARM). If you have a Raspberry Pi 2 there's a few
modifications that you can make to utilize the extra cores to expedite this
process.

I've written this quick Github Gist to download and compile on your Raspbery Pi
2. If you come across a `virtual memory exhausted` error, you need to increase
the swap space by [following these instructions][swap_size_instructions].
Increasing your swap size to 512MB should be fine but **do not forget to change
this value back to 100MB** once you have successfully compiled RethinkDB.

<script src="https://gist.github.com/dalanmiller/2365fb938fe61f4761c1.js"></script>

You can automatically run the script by just copy and pasting this line into
your Raspberry Pi 2 terminal:

```
curl -sL https://gist.githubusercontent.com/dalanmiller/2365fb938fe61f4761c1/raw/22c8c138b48259b3031dfab5edf2f7ece043ee3c/download_rethinkdb_for_raspberry_pi_2.sh | sh
```

Once it's complete, you want to make sure that RethinkDB start when your
RethinkDB powers up. To do that, you want to edit the `/etc/rc.local` file to
look like this:

``` bash
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi

rethinkdb --bind all --server-name rbpi_rethinkdb -d /home/pi --daemon

exit 0
```

To get RethinkDB running right now, just run this same command you've added:

```
rethinkdb --bind all --server-name rbpi_rethinkdb -d /home/pi --daemon
```

# The code

After you have the hardware setup and where you want it, the rest is a piece of
cake. I've written two scripts that will get this project running. The first
will be scheduled to run using `cron` and the second will be constantly
listening for updates to the database to push them out to you via the PushBullet
API.

### The cron job

This code assumes you have installed the `rethinkdb` and `Adafruit_DHT` modules.
Everything else used is in the standard Python libraries.

To install the RethinkDB Python driver [it's as easy as](https://www.youtube.com/watch?v=ho7796-au8U&feature=youtu.be&list=RDho7796-au8U&t=16):

```
pip install rethinkdb

#Or if you don't have pip installed: sudo easy_install pip
```

To install the Adafruit_DHT modules, first [clone this repository][adafruit_dht]. Then run `python setup.py install` from within the
repository directory itself.

The following script is what will be called via a `cron` job to collect
temperature and humidity data. We don't need to manually create the database and
table as the script will check for their existence and create them if necessary.
Either copy paste this gist or `git clone` this [URL][pusherGist].

<script src="https://gist.github.com/dalanmiller/7d6bb95e70721d70e6d9.js"></script>

To add this as a `cron` job, enter `sudo crontab -e` on your Raspberry Pi 2. My
`crontab` at this moment looks like this:

```
* * * * * sudo python ~/pusherRethinkDB.py
```

This runs the script [every minute, for every hour, for every day of the week, for every day of the month, for every day of the week][daft_punk]. To run this
less frequently you would change the first asterisk to something like `*/5` for
every five minutes or `*/15` to run every fifteen minutes. For more background
on what `cron` is and how it works, you should check out [Cron on Wikipedia][cron_wikipedia] or the [Ubuntu documentation on Cron][cron_ubuntu].

To make sure the script works properly and to generate the necessary database
and table within RethinkDB for the project, just run:

```bash
#'sudo' is necessary here to access the GPIO pins
sudo python ~/pusherRethinkDB.py
```

If your script hangs at `Attempting to read from sensor`, then you should double
check your jumper wires to make sure that they are connected firmly.

### The changefeed whisperer

The other script we are going to run is the one listening to a RethinkDB
changefeed and pushing an alert to you when a temperature read is too high or
too low. Because of the asynchronous nature of changefeeds, Javascript/Node.js
is a natural fit that is easy to follow in terms of logic thanks to the uses of
Promises.

To run this code you'll first need to install Node.js and `npm`. The easiest way
to do that is to first add the nodesource.com PPA to your APT repositories and
then install `node` and `npm` normally.

``` bash
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs npm
```

Then we need to install the necessary packages for the script from `npm`.

``` bash
sudo npm install -g pushbullet rethinkdb forever bluebird
```

In order to push notifications for this project I decided to use PushBullet.
PushBullet is a text \| link \| file notification service and has extensions for
browsers ([Chrome][chrome_pushbullet], [Safari][safari_pushbullet],
[Firefox][firefox_pushbullet]) and nice native apps for both
[iOS][ios_pushbullet] and [Android](android_pushbullet), as well as a simple
developer API. Truly, an easy five-minute message and notification queue for all
your projects. Before you can use the API you need to [sign up for an account][pushbullet_home], and then grab your access token from the [account page][pushbullet_account_page]. Then just copy paste this into a file in the
same directory as your `watcherRethinkDB.js` in a file named `token`.
`watcherRethinkDB.js` will expect to find this file and read it to find your
token.

Now that we have all of our node.js dependencies installed, we can now run the
`watcherRethinkDB.js` script. Once again, you can copy and paste this gist or
`git clone` from this [URL][watcherGist] on your RBPi. Just make sure that the
script is referenced correctly further along.

<script src="https://gist.github.com/dalanmiller/29ffcc3394c41d70ca8b.js"></script>

We can set this up to start on bootup of the Raspberry Pi easily by adding
another line to `cron`. `cron` has a few special shortcut commands and the one
for the job here is `@reboot` which says to run a command only at reboot and not
until the next reboot. So `sudo crontab -e` once more and add the following
line.

```
@reboot forever start ~/watcherRethinkDB.js
```

Typically, you execute node files by running `node script.js` but we are going
to use the [`forever`][forever] utility which will ensure that even if our
`watcherRethinkDB.js` crashes, it will automatically restart it . To get it
going right now, just run:

```
forever start ~/watcherRethinkDB.js
```

# Finalizing your first sensor setup

Lastly, we are going to give your setup a whirl. Reboot your Raspberry Pi and
then get back to the command line. Let's check if the watcher script is running:

```
ps -ef | grep node
```

You should see something similar to this:

```
pi@dalanmiller-pi ~ $ ps -ef | grep forever
pi        3155     1 14 13:46 ?        00:00:02 /usr/bin/nodejs /usr/lib/node_modules/forever/bin/monitor watcherRethinkDB.js
```

Now, I recommend leaving the portion of the script that will push you a message
even at a nominal temperature uncommented out just to make sure it works and
comment it out once you get a message through PushBullet as to not spam you with
"The temperature is totally fine." Once you get that message once, you've finished baking your first Raspberry Pi project!

One hard part of figuring out a project is the real-world use case. But there
are really countless places where having a temperature sensor could be handy:

* Making sure your pets aren't too cold or warm at home.
* Are your water pipes on the verge of freezing while you're on vacation?
* Keeping an optimal temperature in your greenhouse or small gardening experiment.
* Monitoring a basement or home areas near water for humidity and possible mold.
* Find out if a pesky family member is turning up the heat in the middle of summer.

Now that you have RethinkDB going on your Pi, you have an easy way to not only
be notified when the temperature hits a desired threshold but also a way to
easily query all collected data without burying yourself in text logs or
worrying about losing your data when your Raspberry Pi resets.

Need help or advice on how to setup your Pi or connect to your Pi wirelessly?  
Or just advice on your project? [Hit me (@dalanmiller) up on Twitter][@dalanmiller].

# The sixth sensor (going further)

Later on you may want to come back and do some analyses on the temperature or
humidity observations you've collected. Here are some examples of advanced
queries that could help get you bootstrapped a little faster.

<script src="https://gist.github.com/dalanmiller/1cd4fc913d070170c1b9.js"></script>

<style>
  .gist .blob-code {
    padding:1px 26px !important;
  }
</style>

[@dalanmiller]:https://twitter.com/dalanmiller
[adafruit_dht]:https://github.com/adafruit/DHT-sensor-library
[adafruit]:https://adafruit.com
[am2302]:https://www.adafruit.com/products/393
[android_pushbullet]:https://play.google.com/store/apps/details?id=com.pushbullet.android&hl=en
[chrome_pushbullet]:https://chrome.google.com/webstore/detail/pushbullet/chlffgpmiacpedhhbkiomidkjlcfhogd?hl=en
[cron_ubuntu]:https://help.ubuntu.com/community/CronHowto
[cron_wikipedia]:https://en.wikipedia.org/wiki/Cron
[daft_punk]:https://www.youtube.com/watch?v=gAjR4_CbPpQ
[firefox_pushbullet]:https://addons.mozilla.org/en-us/firefox/addon/pushbullet/
[forever]: https://github.com/foreverjs/forever
[initd_setup]:http://www.rethinkdb.com/docs/start-on-startup/#quick-setup
[install_retinkdb]:http://rethinkdb.com/docs/install/raspbian/
[ios_pushbullet]:https://itunes.apple.com/us/app/pushbullet/id810352052?mt=8
[jumper_cables]:https://www.adafruit.com/products/266
[pushbullet_account_page]:https://www.pushbullet.com/#settings/account
[pushbullet_home]:https://www.pushbullet.com
[pusherGist]:https://gist.github.com/7d6bb95e70721d70e6d9.git
[rasbian]:https://www.raspbian.org/
[rbpi]:https://www.raspberrypi.org/
[rbpi_pinout]:http://pi.gadgetoid.com/pinout
[safari_pushbullet]:http://update.pushbullet.com/extension.safariextz
[swap_size_instructions]:https://www.bitpi.co/2015/02/11/how-to-change-raspberry-pis-swapfile-size-on-rasbian/
[watcherGist]:https://gist.github.com/29ffcc3394c41d70ca8b.git
