# Postgres and Redis dependencies

Install postgresql database server and redis server.

Add the lua dependencies for postgres and redis:
```
$ apt install lua-sql-postgres lua-redis
```

Install the needed tools:
```
$ apt install gdal-bin
```


# Load the land cover data

Here, we load the European Corine Land Cover (CLC) data, but similar work can be done with other land usage data.

Download the ESRI Geodatabase data from: http://land.copernicus.eu/pan-european/corine-land-cover/clc-2012

Since Europe is a huge file, there also available dataset country by country or in other formats, look at your local OpenData portal.

Selects the interesting classes from the original database and converts it to Shapefile. Maps CLC classes to internal code, 1 for dense urban, 2 for urban, industrial and commercial and 5 for large water body.
(The next commande require gdal >= 1.11, check `ogr2ogr --version`)
```
ogr2ogr -f 'ESRI Shapefile' -dialect SQLite -sql "SELECT CASE WHEN code_12 IN(111) THEN 1 WHEN code_12 IN(112, 121, 123, 124, 133, 141, 142) THEN 2 WHEN code_12 IN(511, 512, 522) THEN 5 END AS code, shape FROM clc12_Version_18_5 WHERE CODE_12 IN (111, 112, 121, 123, 141, 142, 511, 512, 522)" -nln urban urban.shp clc12_Version_18_5.gdb -t_srs EPSG:4326
```

Converts it to sql, load into database and add a geospatial index for queries speedup.
```
shp2pgsql -d -s 4326 urban.shp > urban.sql.
psql < urban.sql
psql -c "CREATE INDEX index idx_urban_geom ON urban USING gist(geom);"
```


# Profile usage and configuration

Throug the osrm-extract the profil will make SQL queries on the land usage data.
As SQL queries take time during the process, the computed speed for ways are cached in the redis database.
So next runs of osrm-extract will reuse the cached value for unchanged objects from OSM and speed the extraction process.

Adapt the configuration file `urban-density-config.lua` with your cerdentials.


# OSRM setup

To match landuse polygons the profile need to know the way geometry.

In order to have it, we need to preprocess the PBF file with osmium to add geometry to ways:
```
$ osmium add-locations-to-ways --verbose --keep-untagged-nodes --ignore-missing-nodes -F pbf -f pbf -o europe-ways_with_geom.osm.pbf -O europe.osm.pbf
```

The extract is done with `--with-osm-metadata` to get the OSM object version in profile, it's for the cache, to detect when object (and possiblely geometry) changed.
```
$ osrm-extract -p profiles/car.lua europe-ways_with_geom.osm.pbf --with-osm-metadata
```
