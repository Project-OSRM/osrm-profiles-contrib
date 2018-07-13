# Urban Density

Profile based on default car profile. Use diff to review the changes.

## Why
The real speed not only depends of the road type and the maxspeed limit, but also from the context of the road.
A common street limited at 50 Km/h is not the same as a country side road also limited at 50 km/h.
In urban area average speed also depends e.g. on traffic.

The idea is to use multiple speed profiles based of the surounding landuse: country side, urban, industrial area...

## How
Using a databased of land usage, each road segement is splited by the limits of land usage.
A speed profile table is selected for each segement in according to the landuse, then the speed is chooseen based on the road type.
Finally, the total duration of the segement is computed and saved in cache to speedup next run of osrm-extract.
