---
layout: post
title: "Building an earthquake map with RethinkDB and GeoJSON"
author: Ryan Paul
author_github: segphault
---

[RethinkDB 1.15][1] introduced new [geospatial features][geo] that can help you
plot a course for smarter location-based applications. The database has new
geographical types, including points, lines, and polygons.  Geospatial queries
makes it easy to compute the distance between points, detect intersecting
regions, and more. RethinkDB stores geographical types in a format that
conforms with the GeoJSON standard.

[1]: http://rethinkdb.com/blog/1.15-release/
[geo]: http://rethinkdb.com/docs/geo-support/javascript/

Developers can take advantage of the new geospatial support to simplify the
development of a wide range of potential applications, from location-aware
mobile experiences to specialized GIS research platforms. This tutorial
demonstrates how to build an earthquake map using RethinkDB's new geospatial
support and an open data feed hosted by the USGS.
<!--more-->

<img src="/assets/images/posts/2014-09-09-earthquake-geojson.png">

# Fetch and process the earthquake data

The USGS publishes a global feed that includes data about every earthquake
detected over the past 30 days. The feed is updated with the latest earthquakes
every 15 minutes. This tutorial uses a [version of the feed]() that only
includes earthquakes that have a magnitude of 2.5 or higher.

[2]: http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson

In the RethinkDB administrative console, use the `r.http` command to fetch the
data:

```javascript
r.http("http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson")
```

The feed includes an array of geographical points that represent earthquake
epicenters. Each point comes with additional metadata, such as the magnitude
and time of the associated seismic event. You can see a sample earthquake
record below:

```javascript
{
  id: "ak11383733",
  type: "Feature",
  properties: {
    mag: 3.3,
    place: "152km NNE of Cape Yakataga, Alaska",
    time: 1410213468000,
    updated: 1410215418958,
    ...
  },
  geometry: {
    type: "Point",
    coordinates: [-141.1103, 61.2728, 6.7]
  }
}
```

The next step is transforming the data and inserting it into a table. In cases
where you have raw GeoJSON data, you can typically just wrap it with the
`r.geojson` command to convert it into native geographical types. The USGS
earthquake data, however, uses a non-standard triple value for coordinates,
which isn't supported by RethinkDB. In such cases, or in situations where you
have coordinates that are not in standard GeoJSON notation, you will typically
use commands like `r.point` and `r.polygon` to create geographical types.

Using the `merge` command, you can iterate over earthquake records from the
USGS feed and replace the value of the `geometry` property with an actual point
object. The output of the `merge` command can be passed directly to the
`insert` command on the table where you want to store the data:

```javascript
r.table("quakes").insert(
  r.http("earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson")("features")
    .merge(function(quake) {
      return {
        geometry: r.point(
          quake("geometry")("coordinates")(0),
          quake("geometry")("coordinates")(1))
      }
    })
  )
```

The `r.point` command takes longitude as the first parameter and latitude as
the second parameter, just like GeoJSON coordinate arrays. In the example
above, the `r.point` command is passed the coordinate values from the
earthquake object's `geometry` property.

As you can see, it's easy to load content from remote data sources into
RethinkDB. You can even use the query language to perform relatively
sophisticated data transformations on the fetched data before inserting it into
a table.

# Perform geospatial queries

The next step is to create an index on the `geometry` property. Use the
`indexCreate` command with the `geo` option to create an index that supports
geospatial queries:

```javascript
r.table("quakes").indexCreate("geometry", {geo: true})
```

Now that there is an index, try querying the data. For the first query, try
fetching a list of all the earthquakes that took place within 200 miles of
Tokyo:

```javascript
r.table('quakes').getIntersecting(
  r.circle([139.69, 35.68], 200,
    {unit: "mi"}), {index: "geometry"})
```

In the example above, the `getIntersecting` command will find all of the
records in the `quakes` table that have a geographic object stored in the
`geometry` property that intersects with the specified circle. The `r.circle`
command creates a polygon that approximates a circle with the desired radius
and center point. The `unit` option tells the `r.circle` command to use a
particular unit of measurement (miles, in this case) to compute the radius. The
coordinates used in the above example correspond with the latitude and
longitude of Tokyo.

Let's say that you wanted to get the largest earthquake for each individual
day. To organize the earthquakes by day, use the `group` command on the date.
To get the largest from each day, you can chain the `max` command and have it
operate on the magnitude property.


```javascript
r.table("quakes").group(r.epochTime(
    r.row("properties")("time").div(1000)).date())
  .max(r.row("properties")("mag"))
```

The USGS data uses timestamps that are counted in milliseconds since the UNIX
epoch. In the query above, `div(1000)` is used to normalize the value so that
it can be interpreted by the `r.epochTime` command. It's also worth noting that
commands chained after a `group` operation will automatically be performed on
the contents of each individual group.

# Build a simple API backend

The earthquake map application has a simple backend built with node.js and
Express. It implements several API endpoints that client applications can
access to fetch data. Create a `/quakes` endpoint, which returns a list of
earthquakes ordered by magnitude:

```javascript
var r = require("rethinkdb");
var express = require("express");

var app = express();
app.use(express.static(__dirname + "/public"));

var configDatabase = {
  db: "quake",
  host: "localhost",
  port: 28015
}

app.get("/quakes", function(req, res) {
  r.connect(configDatabase).then(function(conn) {
    this.conn = conn;

    return r.table("quakes").orderBy(
      r.desc(r.row("properties")("mag"))).run(conn);
  })
  .then(function(cursor) { return cursor.toArray(); })
  .then(function(result) { res.json(result); })
  .finally(function() {
    if (this.conn)
      this.conn.close();
  });
});

app.listen(8081);
```

Add an endpoint called `/nearest`, which will take latitude and longitude
values passed as URL query parameters and return the earthquake that is closest
to the provided coordinates:

```javascript
app.get("/nearest", function(req, res) {
  var latitude = req.param("latitude");
  var longitude = req.param("longitude");

  if (!latitude || !longitude)
    return res.json({err: "Invalid Point"});
 
  r.connect(configDatabase).then(function(conn) {
    this.conn = conn;

    return r.table("quakes").getNearest(
      r.point(parseFloat(longitude), parseFloat(latitude)),
      { index: "geometry", unit: "mi" }).run(conn);
  })
  .then(function(result) { res.json(result); })
  .finally(function(result) {
    if (this.conn)
      this.conn.close();
  });
});
```

The `r.point` command in the code above is given the latitude and longitude
values that the user included in the URL query. Because URL query parameters
are strings, you need to use the `pareFloat` function (or a plus sign prefix)
to coerce them into numbers. The query is performed against the `geometry`
index.

In addition to returning the closest item, the `getNearest` command also
returns the distance. When using the `unit` option in the `getNearest` command,
the distance is converted into the desired unit of measurement.

# Build a frontend with AngularJS and leaflet

The earthquake application's frontend is built with [AngularJS][], a popular
JavaScript MVC framework. The map is implemented with the [Leaflet library][]
and uses tiles provided by the [OpenStreetMap][] project.

[AngularJS]: https://angularjs.org/
[Leaflet library]: http://leafletjs.com/
[OpenStreetMap]: http://www.openstreetmap.org/

Using the AngularJS `$http` service, retrieve the JSON quake list from the
node.js backend, create a map marker for each earthquake, and assign the array
of earthquake objects to a variable in the current scope:

```javascript
$scope.fetchQuakes = function() {
  $http.get("/quakes").success(function(quakes) {
    for (var i in quakes)
      quakes[i].marker = L.circleMarker(L.latLng(
        quakes[i].place.coordinates[1],
        quakes[i].place.coordinates[0]), {
        radius: quakes[i].properties.mag * 2,
        fillColor: "#616161", color: "#616161"
      });

    $scope.quakes = quakes;
  });
};
```

To display the points on the map, use Angular's `$watchCollection` to apply or
remove markers as needed when a change is observed in the contents of the
`quakes` array. 

```javascript
$scope.map = L.map("map").setView([0, 0], 2);
$scope.map.addLayer(L.tileLayer(mapTiles, {attribution: mapAttrib}));

$scope.$watchCollection("quakes",
  function(addItems, removeItems) {
    if (removeItems && removeItems.length)
      for (var i in removeItems)
        $scope.map.removeLayer(removeItems[i].marker);

    if (addItems && addItems.length)
      for (var i in addItems)
        $scope.map.addLayer(addItems[i].marker);
  }
);
```

You could just call `$scope.map.addLayer` in the `fetchQuakes` method to add
markers directly as they are created, but using `$watchCollection` is more
idiomatically appropriate for AngularJS---if the application adds or removes
items from the array later, it will dynamically add or remove the corresponding
place markers on the map.

The application also displays a sidebar with a list of earthquakes. Clicking on
an item in the list will focus the associated point on the map. That part of
the application was relatively straightforward, built with a simple `ng-repeat`
that binds to the `quakes` array.

To complete the application, the last feature to add is support for plotting
the user's own location on the map and indicating which earthquake in the list
is the closest to their position.

The HTML5 Geolocation standard introduced a browser method called
`geolocation.getCurrentPosition` that provides coordinates of the user's
current location. In the callback for that method, assign the received
coordinates to the `userLocation` variable in the current scope. Next, use the
`$http` service to send the coordinates to the `/nearest` endpoint.

```javascript
$scope.updateUserLocation = function() {
  navigator.geolocation.getCurrentPosition(function(position) {
    $scope.userLocation = position.coords;

    $http.get("/nearest", {params: position.coords})
      .success(function(output) {
        if (output.length)
          $scope.nearest = output[0].doc;
      });
  });
};
```

To display the user's position on the map, use `$watch` to observe for changes
to the value of `userLocation`. When it changes, create a new place marker at
the user's coordinates.

```javascript
$scope.$watch("userLocation", function(newVal, oldVal) {
  if (!newVal) return;
  
  if ($scope.userMarker)
    $scope.map.removeLayer($scope.userMarker);

  var point = L.latLng(newVal.latitude, newVal.longitude);
  $scope.userMarker = L.marker(point, {
    icon: L.icon({iconUrl: "mark.png"})
  });

  $scope.map.addLayer($scope.userMarker);
});
```

# Put a pin in it

To view the complete source code, you can check out the [repository on
GitHub][3]. To try the example, run
`npm install` in the root directory and then execute the application by running
`node app.js`.

[3]: https://github.com/rethinkdb/earthquake-map

To learn more about using geospatial queries in RethinkDB, check out the
[documentation][]. Geospatial
support is only one of the great new features introduced in RethinkDB 1.15. Be
sure to read the [release
announcement][] to get the whole story.

[documentation]: http://rethinkdb.com/docs/geo-support/javascript/
[release announcement]: http://rethinkdb.com/blog/1.15-release/
