#!/bin/bash

# Usage:
# ./getGarden.sh

# Vars
SITE="https://leekwars.com/api"

# Import credentials & IDs
. .creds

# Get token
curl -sS ${SITE}/farmer/login-token/$ID/$PASSWORD > mdp_leek.json
token=$(cat mdp_leek.json|jq -r ".token")

# Get the opponents in the garden
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

# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST ${SITE}/farmer/disconnect >/dev/null

