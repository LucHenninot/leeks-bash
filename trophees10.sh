#!/bin/bash

# Parse les trophées et compte qui en a le plus
# Pages utiles :
# https://leekwars.com/api/trophy/get-all
# curl -sS https://leekwars.com/api/trophy-template/get/triumphant/fr | jq -r '.first_farmers[0].name'

trop=$(curl -sS https://leekwars.com/api/trophy/get-all  | jq -r '.trophies' | jq -r '.[].code')

rm -rf T10 2> /dev/null
mkdir -p T10

for T in $trop; do
	echo "> $T"
	TR=$(curl -sS https://leekwars.com/api/trophy-template/get/$T/fr)
	for x in 0 1 2 3 4 5 6 7 8 9; do
		F=$(echo "$TR" | jq -r ".first_farmers[$x].name")
		echo "   $x $F"
		echo "$T" >> T10/$F
	done
done

rm -f T10/null
