# leeks-bash
Bash scripts for [leekwars.com](https://leekwars.com/) API  

Some of these scripts makes intensive use of [jq](https://stedolan.github.io/jq/) and [sqlite](https://www.sqlite.org/index.html).  
You can install them with your package manager (`yum`, `apt-get`, `dnf`, ...).

> `sudo yum install sqlite3 jq`


## Scripts
| Script | Description |
| --- | ----- |
| [Credentials](#Credentials) | Set your login, password and IDs |
| [updateRatio.sh](#updateRatiosh) | Store your fights in a database for future analysis |
| [potager.sh](#potagersh) | Gives you useful stats for your next fights in the [garden](https://leekwars.com/garden/) |
| [try200.sh](#try200sh) | Launch test fights against your 200 talent neighbours (including you), or given rank page |
| [fullMoon.sh](#fullMoonsh) | Get the fullmoon days (UTC time) |


## Credentials
you have to create a `.creds` file containing your farmer name & password, your farmer ID and leek ID:
```
$ cat .creds
ID="FARMER_NAME"
PASSWORD="GuessWhat"
id_farmer=888888
id_leek=999999
```
It will be used to authenticate with some API.


## updateRatio.sh
Collects the fights of a leek and stores them in a database (sqlite).  
Usage: `./updateRatio.sh`

This script needs a [.creds file](#Credentials).

Each fight can result in a win, draw or defeat.  
Each fight is stored with a corresponding score of 1, 0 or -1  
You can just filter the database with one of your leeks in leek1, and a target in leek2.

Example:
```
sqlite> SELECT * FROM fights WHERE leek1='Turbigo' AND leek2='Terriz';
34874271|Turbigo|Terriz|2|0|-1
34874307|Turbigo|Terriz|2|0|1
34874326|Turbigo|Terriz|2|0|-1
34874328|Turbigo|Terriz|2|0|1
34874357|Turbigo|Terriz|2|0|1
34874363|Turbigo|Terriz|2|0|1
34874408|Turbigo|Terriz|2|0|1
34874412|Turbigo|Terriz|2|0|-1
34874417|Turbigo|Terriz|2|0|1
34874423|Turbigo|Terriz|2|0|-1
34874456|Turbigo|Terriz|2|0|-1
```
I have 6 victories and 5 defeats against Terriz.

You can also make some complex requests to get your stats per leek :  
`SELECT DISTINCT leek1, leek2, COUNT(leek1) as Combats, SUM(result) as Trends FROM fights WHERE (context=2 OR context = 1) AND type=0 GROUP BY leek1, leek2 ORDER BY leek1, Trends DESC, Combats;`

```
...
Turbigo|Competitor|3|3
Turbigo|Espada|2|2
Turbigo|Terriz|11|1
Turbigo|Murdereurgg|2|0
Turbigo|Nmnmmnm|1|-1
Turbigo|Sabanto|1|-1
Turbigo|bislpo|12|-2
...
```

It tells me that I did 11 fights with Terriz, the win/defeat ratio is positive by 1.  
I may defeat Competitor and Espada, but I should avoid bislpo.

A much easyer way to see the results and filter the fights is to use a sqlite browser such as [DB Browser for SQLite](https://sqlitebrowser.org/).

The fights are stored in a `fights` directory as compressed json files.  
The json filename is `fights/fight_id.json.gz`.

The opponents are stored in a `leeks` directory as compressed json files.  
The json filename is `leeks/leek_name.json.gz`.

You can replay the fight with <https://leekwars.com/fight/fight_id>.  
Or, parse the file with `zcat fight_id.json.gz | jq .`.


## potager.sh
This script needs a [.creds file](#Credentials).

Usage: `./potager.sh [leek_name]`

### If no leek_name is given:
It scans 5 opponents in the garden, and gives you some useful stats from the database filled with [updateRatio.sh](#updateRatio.sh).

Sample output:
```
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
| You                  | Rank Opponent        | Fights   | Wins     | Draws    | Defeats  | Wins %   | Draws %  | Def. %   | Trend    |
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
| JeSappelleGroot      | 1234  MiteEnPullover | 0        | 0        | 0        | 0        | ?        | ?        | ?        | 0        |
| JeSappelleGroot      | 1254  LoveInTheAir   | 7        | 2        | 3        | 2        | 28       | 42       | 28       | -1       |
| JeSappelleGroot      | 1247  TaMereEnShort  | 4        | 1        | 3        | 0        | 25       | 75       | 0        | 1        |
| JeSappelleGroot      | 1250  FeasantPlucker | 6        | 0        | 0        | 6        | 0        | 0        | 100      | -5       |
| JeSappelleGroot      | 1244  SergeDalaïLama | 5        | 0        | 0        | 5        | 0        | 0        | 100      | -5       |
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
```
This can help you decide your future opponent regarding the past fights.  
The `Trend` column gives you a number between `-5` and `5`, representing the last 5 combats.  
`-5` tells you lost all of your last 5 combats, `5` you won.

`?` in stats means you've not met this opponent yet.  
Tip: make a test fight against him and relaunch `potager.sh`.

### If a leek name is given:
It displays the stats if you've already fought that leek.

## try200.sh
This script needs a [.creds file](#Credentials).

Usage: `./try200.sh [page]`

It gets your ranking from the [ranking page](https://leekwars.com/ranking/active), and launches test fights againts the 200 leeks around your talent.  
Assuming you're on talent ranking page 14: it will makes you test the leeks from pages 12, 13, 14 & 15.

Or, if a page is given: just try the 50 leeks in that page.

Useful to fill the database with [updateRatio.sh](#updateRatio.sh) and help you decide with [potager.sh](#potager.sh).

**Note 1**: There is a 4s delay between each fight, to not overload the [web site](https://leekwars.com/).  
It is **important** to launch `try200.sh` in calm hours. Not when the BR or tounraments are running!  

**Note 2**: With a 4s delay the script needs ~15 mns.  
If your connection is a bit slow, increase the delay but you shouldn't go under 4.

**Note 3**: Keep an eye to the waiting fights in th [garden](https://leekwars.com/garden/).  
If the waiting fights are over 20 you should stop the script.

**Note 4**: You're limited to 200 test fights.  
Once the script finished you will have only on test fight remaining!

**Note 5**: (I love Notes ^^) wait all the fights has finished before updating the database with [updateRatio.sh](#updateRatio.sh).  
Running fights won't be parsed and you'll loose the result.


## fullMoon.sh
Get the full moon dates and times declared in leekwars.  
Usage: `./fullMoon.sh`

**Note**: Dates & times are UTC+0.


## trophees1.sh
Get the farmer names who got 1st a trophy.  
Generates a `T1` directory containing a file per farmer, and its 1st trophies.  
In `T1` you can sort the farmers with:  
`wc -l * | sort -n -r -k 1 | grep -vw null | head -21`


## trophees10.sh
Same as `trophees1.sh` but for the 10 1st achievers.  
Generates a `T10` directory.


