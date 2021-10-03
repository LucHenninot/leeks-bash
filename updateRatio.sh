#!/bin/bash

# Import credentials
. .creds

# Or, uncomment the following line and set the right number
#id_farmer=MY_FARMER_ID

# SQL part. Needs sqlite3
DB=lw.db
DI=import.txt
cp /dev/null $DI

mkdir -p fights

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
T=$(curl -sS https://leekwars.com/api/farmer/get/$id_farmer | jq -r '.farmer.leeks[].name,.farmer.team.name' | tr '\n' '|' | sed 's/.$//g')

# Get farmer combats in memory
curl -sS https://leekwars.com/api/history/get-farmer-history/$id_farmer | jq .fights > fights.json
F=$(cat fights.json)

# Get number of records
rn=$(jq length fights.json)

# Get max ID from db
MID=$(echo "select max(id) from fights;" | sqlite3 lw.db)
if [ -z "$MID" ]; then MID=0; fi

echo "Got $rn fight records."

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
	if [ "$re" == '?' ]; then continue; fi			# Battle in progress
	if [ $co -eq 5 ]; then continue; fi			# BR
	if [ $co -eq 2 -a $ty -eq 1 ]; then continue; fi	# Farmer fight
	if [ $co -eq 3 -a $ty -eq 1 ]; then continue; fi	# Farmer fight

	# Set fighters in right order: me 1st, the others 2nd
	f1="$l1$t1"
	f2="$l2$t2"
	I=$(echo "$f1" | egrep -wo "$T")
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

	# Store fight's json for future analysis, compressed
	curl -sS https://leekwars.com/api/fight/get/$id | jq . > fights/$id.json
	gzip fights/$id.json
done

# Injection
echo -n "Updating... "
echo ".import $DI fights" | sqlite3 lw.db 2>/dev/null

# Export it to my win desktop for easy view with sqlite browser
# Comment or remove if not needed
cp lw.db /home/luc/Desktop/LS/lw.db

echo " Done."

# Count records in DB
rec=$(echo "SELECT COUNT(leek1) FROM fights" | sqlite3 lw.db)
echo "$rec records in database."
echo ""

