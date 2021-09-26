#!/bin/bash

# Import credentials & IDs
. .creds

# Or uncomment and adapt :
#ID="FARMER NAME"
#PASSWORD="YOUR PASSWORD"
#id_farmer=9999999
#id_leek=9999999

# Get token
curl -sS https://leekwars.com/api/farmer/login-token/$ID/$PASSWORD > mdp_leek.json
token=$(cat mdp_leek.json|jq -r ".token")

# Get garden
G=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" https://leekwars.com/api/garden/get-leek-opponents/$id_leek | jq -r '.opponents[].name' 2>/dev/null)

P1=$(echo "$G" | sed -n '1p')
P2=$(echo "$G" | sed -n '2p')
P3=$(echo "$G" | sed -n '3p')
P4=$(echo "$G" | sed -n '4p')
P5=$(echo "$G" | sed -n '5p')


echo "SELECT DISTINCT leek1, leek2, COUNT(leek1) as Combats, SUM(result) as Trend FROM fights WHERE (context=2 OR context = 1) AND type=0 AND leek2 in ('$P1', '$P2', '$P3', '$P4', '$P5') GROUP BY leek1, leek2 ORDER BY leek1, Trend DESC, Combats DESC;" | sqlite3 -header -column lw.db


# Disconnect
#curl -sS -H "Accept: application/json" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect

