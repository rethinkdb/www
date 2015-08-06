---
layout: post
title: "Rethinking temperature, sensors, and Raspberry Pi"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image: 2015-07-31-temperature-sensors-and-a-side-of-pi-hero.png
---

Getting started on your first hardware project can be difficult. Luckily these days we have things like the Raspberry Pi. which put almost everything we need into a nice bundled package to get started on your first cool hardware project. Even better, the Raspberry Pi runs Rasbian, a variant of Debian, which makes it pretty familiar with those already comfortable with popular Linux distributions. The next step is to connect a sensor and it's definitely easier than you think. But the question always remains, once I'm collecting my data, where will I store it and how do I easily setup some sort of notification service? In this post, I'll tell you what you need to do to connect your first sensor, get RethinkDB going on your Raspberry Pi, and push that data to all your devices using PushBullet.

<!--more-->

**I demo'd the result of this tutorial in a talk I gave at the 7/28/15 RethinkDB meetup at HeavyBit in SFO**

I wasn't sure what I wanted to do for my first hardware project but having a Raspberry Pi gave me a great place to start. I knew though that if I kept worrying about voltages and GPIO pins I would never get started. So I took a leap and went to [Adafruit.com][adafruit] and purchased my first tempeature and humidity sensor. I choose the [AM2302][am2302] because of the support I found on the Adafruit website and the special Python-wrapped C libraries which Adafruit had already written and put up on Github.

After my sensor arrived, I realized the three cables coming from the sensor couldn't be directly connected to the Raspberry Pi as the GPIO pins are just that, pins. Where somewhere In my mind I had figured they were female connectors. Not wanting to dive into soldering and burn my fingers or play with molten metal, I decided that I would much rather ride my bike out to Fry's and get some [female-female jumper cables][jumper_cables] for a couple bucks.

Getting started working with the GPIO pins is also somewhat challenging. As I had already lost my Raspberry Pi instructions within the first 30 seconds of opening the box (Were there any instructions in there anyway?) Luckily the Internet is fully of documentation on the layout of the GPIO pins for each version of the Raspberry Pi. My Raspberry Pi 2 being somewhat different than the previous two. Make sure when wiring up your project that you follow a pinout guide [such as this one][rbpi_pinout]. Plugging the wires in the wrong places can render your Raspberry Pi unusable, so check twice and plug once!

## Getting RethinkDB setup on the Raspberry Pi

I wish I could say that this part of the process took unprecedented hacker skill or intelligence beyond measure on my part, but it's actually a piece of cake.

Following the [directions here][install_rethinkdb] and assuming you have Rasbian (or other Debian deviant) on your Raspberry Pi you should be good to go. The process takes a couple hours to compile RethinkDB from source (I'm working on the .deb package for ARM). If you have a Raspberry Pi 2 there's a few modifications that you can make to utilize the extra cores to expedite this process.

I've written this quick Github Gist to download and compile on your Raspbery Pi 2

<script src="https://gist.github.com/dalanmiller/2365fb938fe61f4761c1.js"></script>

Once it's complete, you want to make RethinkDB start on bootup when your RethinkDB powers up. To do that follow the [instructions here][initd_setup] and then run `sudo /etc/init.d/rethinkdb restart` and RethinkDB should start up for the first time.

## The Code

After you have the hardware setup and where you want it, the rest is a piece of cake. I've written two scripts that will get this project running. The first will be scheduled to run using `cron` and the second will be constantly listening for updates to the database to push them out to you via the PushBullet API.

### The Cron Job

This code assumes you have installed the rethinkdb and Adafruit_DHT modules, and everything else is in the standard Python libraries.

To install the RethinkDB Python driver it's as easy as:

```
pip install rethinkdb

#Or if you don't have pip installed: sudo easy_install pip
```

To install the Adafruit_DHT modules, first [clone this repository][adafruit_dht]. Then run `python setup.py install` from within the repository directory.

This code is what will be called via cron job to collect temperature and humidity data. We don't need to manually create the database and table as the script will check for their existence and create them if necessary.

<script src="https://gist.github.com/dalanmiller/7d6bb95e70721d70e6d9.js"></script>

To add this as a `cron` job, enter `sudo crontab -e` on your Raspberry Pi 2. My `crontab` looks like this:

```
* * * * * sudo python ~/pusherRethinkDB.py
```

This runs the script [every minute, for every hour, for every day of the week, for every day of the month, for every day of the week][daft_punk]. To run this less frequently you would change the first asterisk to something like `*/5` for every five minutes or `*/15` to run every fifteen minutes. For more background on what `cron` is and how it works, you should check out [Cron on Wikipedia][cron_wikipedia] or the [Ubuntu documentation on Cron][cron_ubuntu].

### The Changefeed Whisperer

The other script we are going to run is the one listening to a RethinkDB changefeed and pushing you an alert when a temperature read is too high or too low. Because of the asychronous nature of changefeeds I decided to reuse a piece of Node.js code that is easy to follow in terms of logic thanks to the uses of Promises.

To run this code you'll first need to install Node.js and `npm`. The easiest way to do that is to first add the nodesouce.com PPA to your `apt-get` and then install `node` and `npm` normally.

```
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs npm
```

Then we need to install the necessary packages for the script from `npm`.

```
npm install pushbullet rethinkdb nodemon
```

In order to push notifications for this project I decided to use  PushBullet. PushBullet is a [text|link|file] notification service and has extensions for browsers ([Chrome][chrome_pushbullet], [Safari][safari_pushbullet], [Firefox][firefox_pushbullet]) and apps for both iOS and Android, as well as a simple developer API. Truly, an easy five-minute message queue for all your projects. Before you can use the API you need to [sign up for an account][pushbullet_home], and then grab your access token from the [account page][pushbullet_account_page]. Then just copy paste this into a file in the same folder as your `watcherRethinkDB.js` file named `token`. The node script will expect to find this file and read the first line for your token.

Now that we have all of our dependencies installed, we can now run the watcher script.

<script src="https://gist.github.com/dalanmiller/29ffcc3394c41d70ca8b.js"></script>

We can set this up to start on bootup of the Raspberry Pi easily by adding another line to `cron`. `cron` has a few special shortcut commands and the one for the job here is `@reboot` which says to run a command only at reboot and not until the next reboot. So `sudo crontab -e` once more and add the following line.

```
@reboot nodemon ~/watcherRethinkDB.js
```

Typically, you execute node files by running `node script.js` but we are going to use the [`nodemon`][nodemon] utility which will ensure that even if our watcher crashes, it will automatically restart it (as well as when it detects modifications to the file).

## Finalizing Your First Sensor Setup

Lastly, we are going to give your setup a whirl. Reboot your Raspberry Pi and then get back to the command line. Let's check if the watcher script is running:

```
ps -ef | grep node
```

You should see something like this:

[IMAGE FOR PS OUTPUT]

Now, I recommend leaving the portion of the script that will push you a message even at a nominal temperature just to make sure it works and uncomment once you get a message through PushBullet as to not spam you with "The temperature is totally fine."

One hard part of figuring out a project is the real-world use case. But there are really countless places where having a temperature sensor could be handy:

* Making sure your pets aren't too cold or warm at home.
* Are your water pipes on the verge of freezing while you're on vacation?
* Keeping an optimal temperature in your greenhouse.
* Monitoring a basement or areas near water for humidity and thus possible mold.

Now that you have RethinkDB going on your Pi, you have an easy way to not only be notified when the temperature hits a desired threshold but also a way to easily query all collected data without burying yourself in text logs or worry about losing your data in case your Raspberry Pi resets.

Need help or advice on how to setup your Pi or connect to your Pi wirelessly?  [Hit me up on Twitter][@dalanmiller].

## The Sixth Sensor (Going Further)

Later on you may want to come back and do some analyses on the temperature or humidity observations you've collected. Here are some examples of advanced queries that could help get you bootstrapped a little faster.

```
#!/usr/bin/python
import rethinkdb as r
from datetime import datetime, timedelta

conn = r.connect("localhost", 28015, db="telemetry_pi")

#Finding the average temperature & humidity for the past 24 hours
day_ago = datetime.now() - timedelta(hours=24)
r.table("observations")\
  .filter(r.row("datetime") > day_ago))\
  .merge({
    "avg_humidity": r.avg(r.row("temp")),
    "avg_temperature": r.avg(r.row("humidity"))
    }).run(conn)

#Finding the top ten hottest observations per day (or a _single_ maxima for each day)

r.table("observations")\
  .map("")\
  .reduce("")\

#Correlation of humidity to temperature (Btemp + c = humidity)
```

[@dalanmiller]:https://twitter.com/dalanmiller
[adafruit]:https://adafruit.com
[adafruit_dht]:https://github.com/adafruit/DHT-sensor-library
[am2302]:
[chrome_pushbullet]:https://
[cron_ubuntu]:https://help.ubuntu.com/community/CronHowto
[cron_wiki]:https://en.wikipedia.org/wiki/Cron
[daft_punk]:https://www.youtube.com/watch?v=gAjR4_CbPpQ
[firefox_pushbullet]:https://
[initd_setup]:http://www.rethinkdb.com/docs/start-on-startup/#quick-setup
[install_retinkdb]:http://rethinkdb.com/docs/install/raspbian/
[jumper_cables]:
[nodemon]: http://nodemon.io/
[pushbullet_account_page]:https://www.pushbullet.com/#settings/account
[pushbullet_home]:https://www.pushbullet.com
[rbpi_pinout]:http://pi.gadgetoid.com/pinout
[safari_pushbullet]:https://
