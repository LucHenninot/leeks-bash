#!/bin/bash

# Parse les trophées et compte qui en a le plus
# Pages utiles :
# https://leekwars.com/api/trophy/get-all
# curl -sS https://leekwars.com/api/trophy-template/get/triumphant/fr | jq -r '.first_farmers[0].name'

trop=$(curl -sS https://leekwars.com/api/trophy/get-all  | jq -r '.trophies' | jq -r '.[].code')

rm -rf T1 2> /dev/null
mkdir -p T1

for T in $trop; do
	echo "> $T"
	TR=$(curl -sS https://leekwars.com/api/trophy-template/get/$T/fr)
	F=$(echo "$TR" | jq -r '.first_farmers[0].name')
	#D=$(echo "$TR" | jq -r '.description')
	echo "$T" >> T1/$F
done

rm -f t1/null
