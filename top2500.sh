#!/bin/bash

# Need update ?
[ "$1" != "-n" ] && {
	# Reset the file
	cp /dev/null ranking

	# Get the 1st 2500 leeks in rank order
	for p in $(seq 1 50); do
		echo -n "."
		curl -sS https://leekwars.com/api/ranking/get-active/leek/talent/$p | jq ".ranking[] | .id" >> ranking
		sleep .2
	done
echo ""
}

# Get token
. .creds
token=$(curl -sS https://leekwars.com/api/farmer/login-token/$ID/$PASSWORD |jq -r ".token")

# Launching challenge upon each leek
for p in $(cat ranking); do
	echo -n "Trying $p > "
	curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -d "leek_id=$id_leek&target_id=$p&seed=$((RANDOM*RANDOM))" -X POST https://leekwars.com/api/garden/start-solo-challenge | jq -r .fight
	sleep 4
done


# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect >/dev/null
echo ""
