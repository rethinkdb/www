---
layout: post
title: "RethinkDB meets Pok&eacute;mon Go: computing the shortest path between Pokestops with ReQL"
author: Ryan Paul
author_github: segphault
hero_image: 2016-07-18-pokemon-go-banner.png
---

Mobile developer Niantic recently brought Nintendo's popular Pok&eacute;mon franchise
to smartphones with an appealing augmented reality game called Pok&eacute;mon Go. The
much-anticipated launch was super effective, attracting an unprecedented
audience. Around the world, aspiring Pok&eacute;mon trainers are taking to the streets
and hitting gyms, striving to be the very best--like no one ever was.

Here at RethinkDB, we're having a blast(oise?) trying to catch 'em all. We
ventured out of the office last week to join the vast multitude of Pok&eacute;mon
enthusiasts playing the game in downtown Mountain View. In the interest of
increasing the efficiency of our future Pok&eacute;mon adventures, we began to consider
how we could use RethinkDB to determine the best route for hitting all the local
Pok&eacute;stops.

<!--more-->

The Pok&eacute;stop Problem is, of course, a modern variation on the traditional
[Traveling Salesman Problem][tsp] that computer science students have pondered
since the dawn of computing. Given a set of locations, the Traveling Salesman
Problem calls for calculating the shortest path that will take you through each
one without repeating any stops.

Niantic doesn't publish the underlying internal location data that powers the
game, but there are a number of [community-driven efforts][polygon-article] to
produce Gym and Pok&eacute;stop maps with crowdsourced data. We used
[this popular map][map] as a starting point for our experiment. We exported a
full KML dump of the map's content, converted it to JSON at the command line,
and then imported it into RethinkDB. The map's entries are a bit sparse in the
Bay Area, but it has quite a bit of data for the east coast.

With the data in hand, we set out to implement a solution to the Traveling
Salesman Problem in ReQL, RethinkDB's query language. RethinkDB's Daniel Mewes
concocted a solution that consists of a single ReQL query:

```javascript
let generatePermutations = input =>
  // Expand permutations by swapping elements
  r.range(input.count()).fold([input], (currentPermutations, i) =>
    // Swap the `i`th element with itself and all elements behind it
    currentPermutations.concatMap(current =>
        r.range(i, input.count()).map(otherI =>
          current.changeAt(i, current.nth(otherI))
                 .changeAt(otherI, current.nth(i)))));

// `path` must be an array of points
let computePathLength = path =>
  path.fold({dist: 0}, (acc, point) => ({
    dist: acc('dist').add(acc('prev').distance(point)).default(0),
    prev: point
  }))('dist');

let pokestopRoute = (lat, long) => 
  r.table('pokestops')
   .getNearest(r.point(long, lat), {index: "location", maxResults: 5})("doc")
   .pluck('location', 'properties')
   .coerceTo('array')
   .do(generatePermutations)
   .map(path => ({
     path: path,
     length: computePathLength(path('location'))
   }))
  .min('length')
```

Daniel's query takes the closest five Pok&eacute;stops, to a given point,
computes every possible path, adds up the total length of each one, and then
spits out the path with the shortest distance. It's not fast or particularly
practical, but we think that it's a great illustration of ReQL's expressive
power despite its arguable lack of real-world applicability.

The query takes advantage of the new [`fold`][fold] command, which debuted in
[RethinkDB 2.3][r23] earlier this year. It also uses RethinkDB's built-in
[support for GeoJSON types and operators][rgeojson] to compute the distance
between points.

If you'd like to give RethinkDB a (poli?)whirl, peruse our handy
[ten-minute guide][] before you head out into the long grass. To learn more
about what you can do with RethinkDB's query language, be sure to catch our
[introduction to ReQL][reqlintro] and the [query cookbook][].

See you at the gym, fellow Pok&eacute;mon trainers!

[polygon-article]: http://www.polygon.com/2016/7/7/12118576/pokemon-go-pokestop-gym-locations-map-guide
[map]: https://www.google.com/maps/d/u/0/viewer?mid=1NMi554M7U1HFJhxvDuwEBXEFsSU
[r23]: https://rethinkdb.com/blog/2.3-release/
[fold]: https://rethinkdb.com/api/javascript/fold/
[rgeojson]: https://rethinkdb.com/docs/geo-support/javascript/
[tsp]: https://en.wikipedia.org/wiki/Travelling_salesman_problem
[reqlintro]: https://www.rethinkdb.com/docs/introduction-to-reql/
[query cookbook]: https://www.rethinkdb.com/docs/cookbook/javascript/
[ten-minute guide]: https://www.rethinkdb.com/docs/guide/javascript/
