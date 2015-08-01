---
layout: post
title: "Rethinking temperature, sensors, and Raspberry Pi"
author: Daniel Alan Miller
author_github: dalanmiller
hero_image: 2015-07-31-temperature-sensors-and-a-side-of-pi-hero.jpg
---

Getting started on your first hardware project can be difficult. Luckily these days we have things like the Raspberry Pi. which put almost everything we need into a nice bundled package to get started on a cool hardware project. Even better, the Raspberry Pi runs Rasbian, a variant of Debian, which makes it pretty familiar with those already comfortable with popular Linux distributions.

I wasn't sure what I wanted to do for my first hardware project but having a Raspberry Pi gave me a great place to start. I knew though that if I kept worrying about voltages and GPIO pins I would never get started. So I took a leap and went to Adafruit.com and purchased my first tempeature/humidity sensor. I choose the AM2302 because of the support I found on the Adafruit website and the special Python-wrapped C libraries which Adafruit had already written.

After my sensor arrived I realized the three cables coming from the sensor couldn't be directly connected to the Raspberry Pi as the GPIO pins are just that, pins. Where somewhere In my mind I had figured they were female connectors. Not wanting to dive into soldering and burn my fingers, I decided that I would much rather ride my bike out to Fry's and get some female-female jumper cables.

Getting started working with the GPIO pins is also somewhat challenging. As I had already lost my Raspberry Pi instructions within the first 30 seconds of opening the box (Was there any instructions in there anyway?) Luckily the Internet is fully of documentation on the layout of the GPIO pins for each Raspberry Pi. My Raspberry Pi 2 being somewhat different than the previous two. Make sure when wiring up your project that you follow a board such as this one:

 
