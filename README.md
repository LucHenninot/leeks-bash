# leeks-bash
Bash scripts for [leekwars.com](https://leekwars.com/) API

## fullMoon.sh
Get the full moon dates and times declared in leekwars.  
Usage: `./fullMoon.sh`

## trophees1.sh
Get the farmer names who got 1st a trophy.  
Generates a `T1` directory containing a file per farmer, and its 1st trophies.  
In `T1` you can sort the farmers with:  
`wc -l * | sort -n -r -k 1 | grep -vw null | head -21`

## trophees10.sh
Same as `trophees1.sh` but for the 10 1st achievers.  
Generates a `T10` directory.
