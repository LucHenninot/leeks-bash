#!/bin/bash

## Get my rank, try combats against 199 closests leeks by talent (50 below my talent, 150 above).
## Don't try myself (some tried, they got problems ^^).

# Authent: use a .creds file :
#ID="YOUR_FARMER_NAME"
#PASSWORD="YOUR_PASSWORD"
#id_farmer=YOUR_NUMERIC_FARMER_ID
#id_leek=YOUR_NUMERIC_LEEK_ID

. .creds

# Some vars
SITE="https://leekwars.com/api"

# Get token
token=$(curl -sS ${SITE}/farmer/login-token/$ID/$PASSWORD | jq -r ".token")
[ -z "$token" ] && {
	echo "Bad token"
	exit -1
}

# Get my rank
rank=$(curl -sS ${SITE}/ranking/get-leek-rank-active/$id_leek/talent | jq -r .rank)

# Get my current page in the talent ranking
page=$((rank/50 +1))
echo "My ranking page: $page"

# You can do 200 test fights so let's pick leeks from page +1 (lower talent), current page, page -1 and page -2 (more talent)
# Except if you're in page 1 (Hello Beewiz ^^)
[ $page -eq 1 ] && page=2	# Just get down in the current page to get our 4 pages

# Collect the leek IDs
curl -sS ${SITE}/ranking/get-active/leek/talent/$((page-1)) | jq ".ranking[] | .id" > ranking
curl -sS ${SITE}/ranking/get-active/leek/talent/$page | jq ".ranking[] | .id" >> ranking
curl -sS ${SITE}/ranking/get-active/leek/talent/$((page+1)) | jq ".ranking[] | .id" >> ranking
curl -sS ${SITE}/ranking/get-active/leek/talent/$((page+2)) | jq ".ranking[] | .id" >> ranking

# Init fight counter
c=0

# Launching challenge upon each leek
for p in $(cat ranking); do
	# Don't try myself
	# [ $p -eq $id_leek ] && continue

	# Launch try
	printf "%3d Trying $p > " $c
	curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -d "leek_id=$id_leek&target_id=$p&seed=$((RANDOM*RANDOM))" -X POST ${SITE}/garden/start-solo-challenge | jq -r .fight
	c=$((c+1))

	# Don't overload the LW site
        sleep 4
done

# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST ${SITE}/api/farmer/disconnect >/dev/null
