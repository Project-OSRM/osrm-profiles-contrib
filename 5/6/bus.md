# Bus profile : to help calculate bus route

Profile based on car profile. Use diff to review the changes.

## Why

Integration of relation=route for busses on OSM can be tricky.
For example, several GTFS feeds do not specify the shapes of the trips or route

Having a bus profile is a good tool to deduce a efficient route shape from a GTFS feed (by using stop coordinates and timetables, you can use match service)

## Examples

https://sidjy.github.io/gtfs/get_stops_3_758_014195002:95-02_0_81183972-1264906.html

By clicking 'Itineraire', a match service is called, and a route is calculated.

Notice that between stops Bergerie and Le Village, we have a oneway except for busses.

