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

# Get my leek name
M=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" https://leekwars.com/api/leek/get/$id_leek | jq -r .name)

# Get garden
G=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" https://leekwars.com/api/garden/get-leek-opponents/$id_leek | jq -r '.opponents[].name' 2>/dev/null)

P1=$(echo "$G" | sed -n '1p')
P2=$(echo "$G" | sed -n '2p')
P3=$(echo "$G" | sed -n '3p')
P4=$(echo "$G" | sed -n '4p')
P5=$(echo "$G" | sed -n '5p')

if [ "$P1" == "" ]; then
	echo "No stats for $M yet."
	exit 1
fi

# Get some colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m'		# No Color

# Function to get detailed stats for a leek from the DB
# $1: my leek name
# $2: his leek name
function getStats() {
	# No leek ? exit loop
	[ -z "$2" ] && return ""

	# Get wins, draws and defeats
	fights=0
	win=0
	draw=0
	def=0
	trend=0
	stats=$(echo "SELECT result FROM fights WHERE leek1='$1' AND leek2='$2';" | sqlite3 lw.db) 

	# Computing stats
	for s in $stats; do
		[ $s -eq 1 ] && win=$((win+1))
		[ $s -eq 0 ] && draw=$((draw+1))
		[ $s -eq -1 ] && def=$((def+1))
		fights=$((fights+1))
	done

	# Computing trend from last 5 fights
	for s in $(echo "$stats" | tail -5); do
		trend=$((trend+s))
	done

	# Get %
	winp="?"
	drawp="?"
	defp="?"

	# If we had fights
	[ $fights -gt 0 ] && {
		winp=$((win*100/fights))
		drawp=$((draw*100/fights))
		defp=$((def*100/fights))
	}

	# Truncate names if >20 chars
	leek1=$1
	leek2=$2
	[ ${#leek1} -gt 20 ] && leek1=${leek1:0:20} 
	[ ${#leek2} -gt 20 ] && leek2=${leek2:0:20} 

	#echo "$1 $2 $fights $win $draw $def $winp $drawp $defp"
	printf "| %-20s | %-20s | ${BLUE}%-8s${NC} | ${GREEN}%-8s${NC} | ${YELLOW}%-8s${NC} | ${RED}%-8s${NC} | ${GREEN}%-8s${NC} | ${YELLOW}%-8s${NC} | ${RED}%-8s${NC} | %-8s |\n" $leek1 $leek2 $fights $win $draw $def $winp $drawp $defp $trend

}

# Get the stats
tab=$(getStats "$M" "$P1"
getStats "$M" "$P2"
getStats "$M" "$P3"
getStats "$M" "$P4"
getStats "$M" "$P5")

# Filter by win%
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"
echo -e "+ You                  + Opponent             + ${BLUE}Fights${NC}   + ${GREEN}Wins${NC}     + ${YELLOW}Draws${NC}    + ${RED}Defeats${NC}  + ${GREEN}Wins %${NC}   + ${YELLOW}Draws %${NC}  + ${RED}Def. %${NC}   + Trend    +"
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"
echo "$tab" | sort -i -r -t '|' -k 8
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"

# echo -e ".width 25 25 7 5\nSELECT DISTINCT leek1, leek2, COUNT(leek1) as Combats, SUM(result) as Trend FROM fights WHERE leek1 = '$M' AND (context=2 OR context = 1) AND type=0 AND leek2 in ('$P1', '$P2', '$P3', '$P4', '$P5') GROUP BY leek1, leek2 ORDER BY leek1, 0.5+(Trend/Combats/2) DESC, Combats DESC;" | sqlite3 -header -column -batch lw.db


# Disconnect
#curl -sS -H "Accept: application/json" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST https://leekwars.com/api/farmer/disconnect >/dev/null

