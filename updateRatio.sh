#!/bin/bash

# Checks farmer ID
[ -z "$1" ] && {
	echo "Missing farmer ID"
	exit 1
}
leek=$1

# SQL part. Needs sqlite3
DB=lw.db
DI=import.txt
cp /dev/null $DI

# Create it if needed
[ -f $DB ] || {
	TF='CREATE TABLE "fights" (
	"id"		INTEGER NOT NULL UNIQUE,
	"leek1"		TEXT NOT NULL,
	"leek2"		TEXT NOT NULL,
	"context"	INTEGER NOT NULL,
	"type"		INTEGER NOT NULL,
	"result"	INTEGER NOT NULL,
	PRIMARY KEY("id")
);'
	echo "$TF" | sqlite3 $DB
}

# Get leek names and team names
T=$(curl -sS https://leekwars.com/api/farmer/get/$leek | jq -r '.farmer.leeks[].name,.farmer.team.name' | tr '\n' '|' | sed 's/.$//g')

# Get farmer combats in memory
curl -sS https://leekwars.com/api/history/get-farmer-history/$leek | jq .fights > fights.json
F=$(cat fights.json)

# Get number of records
rn=$(jq length fights.json)

# Get max ID from db
MID=$(echo "select max(id) from fights;" | sqlite3 lw.db)
if [ -z "$MID" ]; then MID=0; fi

echo "Got $rn records."

# Parsing
#for i in $(seq 0 10); do
for i in $(seq 0 $((rn-1))); do
	# Get the record
	R=$(echo "$F" | jq ".[$i]")
	
	# Get relevant fields
	id=$(echo "$R" | jq -r '.id')

	# Exit loop if ID <= max ID
	[ $id -le $MID ] && break

	l1=$(echo "$R" | jq -r '.leeks1[].name?')
	l2=$(echo "$R" | jq -r '.leeks2[].name?')
	t1=$(echo "$R" | jq -r '.team1_name?')
	t2=$(echo "$R" | jq -r '.team2_name?')
	co=$(echo "$R" | jq -r '.context')
	ty=$(echo "$R" | jq -r '.type')
	wi=$(echo "$R" | jq -r '.winner')
	re=$(echo "$R" | jq -r '.result')
	if [ "$t1" == "null" ]; then t1=""; fi
	if [ "$t2" == "null" ]; then t2=""; fi
	if [ $co -eq 5 ]; then continue; fi			# BR
	if [ $co -eq 2 -a $ty -eq 1 ]; then continue; fi	# Farmer fight
	if [ $co -eq 3 -a $ty -eq 1 ]; then continue; fi	# Farmer fight

	# Set fighters in right order: me 1st, the others 2nd
	f1="$l1$t1"
	f2="$l2$t2"
	I=$(echo "$f1" | egrep -wo "Turbigo|Godzireau|Suppositoire|EnnemiPubLeek|Hanekawa")
	if [ -z "$I" ]; then
		f1="$l2$t2"
		f2="$l1$t1"
	fi

	# Set points (-1, 0, 1) for defeat, draw, win
	if [ "$re" == "defeat" ]; then re=-1; fi
	if [ "$re" == "draw" ]; then re=0; fi
	if [ "$re" == "win" ]; then re=1; fi

	echo -e "$i $id : context $co type $ty winner $wi $f1 VS $f2 > $re"
	echo "$id|$f1|$f2|$co|$ty|$re" >> $DI
done

# Injection
echo "Updating..."
echo ".import $DI fights" | sqlite3 lw.db 2>/dev/null
cp /home/luc/LS/utils/lw.db /home/luc/Desktop/LS/lw.db
echo "Done."

