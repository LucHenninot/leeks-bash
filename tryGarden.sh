#!/bin/bash

# Usage:
# ./tryGarden.sh

# Vars
SITE="https://leekwars.com/api"

# Import credentials & IDs
. .creds

# Get token
curl -sS ${SITE}/farmer/login-token/$ID/$PASSWORD > mdp_leek.json
token=$(cat mdp_leek.json|jq -r ".token")

# Get my leek name
M=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" ${SITE}/leek/get/$id_leek | jq -r .name)

# No leek name given, get the opponents in the garden
if [ -z "$leek_name" ]; then
	# Get garden
	G=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" ${SITE}/garden/get-leek-opponents/$id_leek | jq -r '.opponents[] | [.name, .id] | @tsv' 2>/dev/null)

	P1=$(echo "$G" | sed -n '1p' | awk '{print $1}')
	P2=$(echo "$G" | sed -n '2p' | awk '{print $1}')
	P3=$(echo "$G" | sed -n '3p' | awk '{print $1}')
	P4=$(echo "$G" | sed -n '4p' | awk '{print $1}')
	P5=$(echo "$G" | sed -n '5p' | awk '{print $1}')

	I1=$(echo "$G" | sed -n '1p' | awk '{print $2}')
	I2=$(echo "$G" | sed -n '2p' | awk '{print $2}')
	I3=$(echo "$G" | sed -n '3p' | awk '{print $2}')
	I4=$(echo "$G" | sed -n '4p' | awk '{print $2}')
	I5=$(echo "$G" | sed -n '5p' | awk '{print $2}')
fi

function tryLeek() {
	echo -n "Trying $1: "
	curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -d "leek_id=$id_leek&target_id=$2&seed=$((RANDOM*RANDOM))" -X POST ${SITE}/garden/start-solo-challenge | jq -r .fight
	# Don't overload the server
	sleep 2
}

tryLeek $P1 $I1
tryLeek $P2 $I2
tryLeek $P3 $I3
tryLeek $P4 $I4
tryLeek $P5 $I5

# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST ${SITE}/farmer/disconnect >/dev/null

