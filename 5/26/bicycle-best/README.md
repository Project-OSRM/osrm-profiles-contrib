# Bicycle - Best

Profile based on default bicycle profile.

## Why
Based on my cycling experience, I optimized the bicycle profile for better safety and cyclability. 

## How
- Adjusted speeds for different surfaces.
- Lowered speeds for low track grades and poor road smoothness.
- Added penalties for roads where cars drive fast, and high traffic roads.
- Take into account roads that have a maxspeed specifically for bicycles.
- Tweak details such as turn delay and u-turn penalty.
- Prefer roads that have cycleway lanes/tracks/etc.

## Examples
Park with surface and smoothness tags present. Bad path quality and surface slows the speeds down.

![Screenshot_663](https://user-images.githubusercontent.com/42336759/156412259-c1ea9169-8c96-4fed-8178-231fbc8452e3.png)

Avoiding high traffic axis to prefer calmer and safer residential roads.

![Screenshot_664](https://user-images.githubusercontent.com/42336759/156412839-eefcb7ed-9a35-4d69-ad0c-ee56b8ad0017.png)

Avoiding axis with high car speed (80km/h) that has no cycleways.

![Screenshot_665](https://user-images.githubusercontent.com/42336759/156413683-6c355857-af60-4ec7-9d0a-b4da3042affc.png)

Not avoiding high traffic axis when a cycleway is present.

![Screenshot_666](https://user-images.githubusercontent.com/42336759/156414036-78cdd744-6ea7-4f89-a079-fcfc8b3f7b05.png)
