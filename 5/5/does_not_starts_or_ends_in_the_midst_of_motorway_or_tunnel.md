# Does not starts or ends in the midst of motorway or tunnel

Profile based on default car profile. Use diff to review the changes.

## Why
Prefers other way than motorway when start point is close of motorway.
Prefer surface way when there is tunnel close somewhere under feet.

## How
Like ferry, removes motorway and tunnel as target of snap for lookup of start and end point.

## Warning
No longer snap to motorways or tunnels when used for rerouting.
