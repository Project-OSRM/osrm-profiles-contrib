# Truck - Soft

Profile based on default car profile. Use diff to review the changes.

## Why
Trucks, aka Heavy Vehicles, have particularities: like speed, vehicle size or restrictions.

## How
The tags about Heavy Vehicles are largely missing on OSM.
This profile is based on four aspects:
- Adjusted Physical size restrictions, strictly respected: height and width.
- Legal size restrictions, softly respected: weight and length. The profile try to avoid restricted ways.
- Heavy Vehicle conditional restrictions, softly respected.
- Highway penalty: stay on major highways and only go on lower highways when needed.

## Warning
OSM data are poor regardly to Heavy Vehicle attributes. The computed route is mainly based on penalties and not rules enforcement. The computed routes may not respect the legal access defined on the ground.
