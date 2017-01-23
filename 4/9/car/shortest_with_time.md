# Shortest with time

Profile based on default car profile. Use diff to review the changes.

## Why
Compute the shortest path.

## How
Sets the same speed on all ways.
Sets speed to 3.6 so the result value (still named `time`) is now a distance in meters.
Sets in the way name the real speed of the segement. In post processing, using the segement speed and the length you can compute the segement duration and then the total duration.

## Warning
Penalties are set to zero to get the right distance value and cannot be take into account when recomputing the time.
