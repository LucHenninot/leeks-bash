# leeks-bash
Bash scripts for [leekwars.com](https://leekwars.com/) API  

Some of these scripts makes intensive use of [jq](https://stedolan.github.io/jq/) and [sqlite](https://www.sqlite.org/index.html).  
You can install them with your package manager (`yum`, `apt-get`, `dnf`, ...).

> `sudo yum install sqlite3 jq`


## Scripts
| Script | Description |
| --- | ----- |
| [Credentials](#Credentials) | Set your login, password and IDs |
| [updateRatio.sh](#updateRatio.sh) | Store your fights in a database for future analysis |
| [potager.sh](#potager.sh) | Gives you usefull stats for your next fights in the gardener |
| [fullMoon.sh](#fullMoon.sh) | Get the fullmoon days (UTC time) |


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
Collects the fights from a farmer and stores them in a sqlite database.  
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

The fights are stored in a `fights` directory as compressed json fights.  
The json filename is `fight_id.json.gz`.

You can replay the fight with <https://leekwars.com/fight/fight_id>.  
Or, parse the file with `zcat fight_id.json.gz | jq .`.


## potager.sh
This script needs a [.creds file](#Credentials).

It scans 5 opponents in the garden, and gives you some usefull stats from the database filled with [updateRatio.sh](#updateRatio.sh).

Sample output:
```
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
| You                  | Opponent             | Fights   | Wins     | Draws    | Defeats  | Wins %   | Draws %  | Def. %   | Trend    |
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
| Turbigo              | Leek@32607           | 3        | 1        | 2        | 0        | 33       | 66       | 0        | 1        |
| Turbigo              | ChaussetteBleue      | 6        | 2        | 3        | 1        | 33       | 50       | 16       | 1        |
| Turbigo              | Djokavex             | 5        | 0        | 3        | 2        | 0        | 60       | 40       | -2       |
| Turbigo              | manant               | 5        | 0        | 0        | 5        | 0        | 0        | 100      | -5       |
| Turbigo              | PtitCoeur            | 4        | 0        | 0        | 4        | 0        | 0        | 100      | -4       |
+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+
```
This can help you decide your future opponent regarding the past fights.  
The `Trend` column gives you a number between `-5` and `5`, representing the last 5 combats.  
`-5` tells you lost all of your last 5 combats, `5` you won.


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


