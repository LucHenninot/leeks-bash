#!/bin/bash

# Need a ranking file with ids
[ -f ranking ] || {
	echo "Please fill a file named 'ranking' with leek IDs to try. One per line"
	exit 1
}

# Get token & login
. .creds
token=$(curl -sS https://leekwars.com/api/farmer/login-token/$ID/$PASSWORD |jq -r ".token")

# Launching challenge upon each leek
for p in $(cat ranking); do
	# Don't try myself
	[ $p -eq $id_leek ] && continue

	# Launch challenge
	echo -n "Trying $p > "
	curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -d "leek_id=$id_leek&target_id=$p&seed=$((RANDOM*RANDOM))" -X POST https://leekwars.com/api/garden/start-solo-challenge | jq -r .fight
	sleep 4
done


# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect >/dev/null
echo ""
