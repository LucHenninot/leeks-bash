#!/bin/bash

# Vars
SITE="https://leekwars.com/api"

# Import credentials & IDs
. .creds

# Or uncomment and adapt :
#ID="FARMER NAME"
#PASSWORD="YOUR PASSWORD"
#id_farmer=9999999
#id_leek=9999999

# Get token
curl -sS ${SITE}/farmer/login-token/$ID/$PASSWORD > mdp_leek.json
token=$(cat mdp_leek.json|jq -r ".token")

# Get my leek name
M=$(curl -sS -H "Authorization: Bearer ${token}" -H "Content-Type: application/x-www-form-urlencoded" ${SITE}/leek/get/$id_leek | jq -r .name)

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

# Function to get leek rank
# $1: leek id
function getRank() {
	# Check args
	[ -z "$1" ] && {
		echo "?"
		break
	}

	# Get leek infos
	leek=$(curl -sS ${SITE}/ranking/get-leek-rank-active/$1/talent | jq -r .)
	rank=$(echo "$leek" | jq -r .rank)
	echo "$rank"
}

# Function to get detailed stats for a leek from the DB
# $1: my leek name
# $2: his leek name
# $3: his leek id
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
	ra=$(getRank $3)

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
	[ ${#leek1} -gt 14 ] && leek1=${leek1:0:14} 
	[ ${#leek2} -gt 14 ] && leek2=${leek2:0:14} 

	#echo "$1 $2 $fights $win $draw $def $winp $drawp $defp"
	printf "| %-20s | %-5d %-14s | ${BLUE}%-8s${NC} | ${GREEN}%-8s${NC} | ${YELLOW}%-8s${NC} | ${RED}%-8s${NC} | ${GREEN}%-8s${NC} | ${YELLOW}%-8s${NC} | ${RED}%-8s${NC} | %-8s |\n" $leek1 $ra $leek2 $fights $win $draw $def $winp $drawp $defp $trend

}

# Get the stats
tab=$(getStats "$M" "$P1" $I1
getStats "$M" "$P2" $I2
getStats "$M" "$P3" $I3
getStats "$M" "$P4" $I4
getStats "$M" "$P5" $I5)

# Filter by win%
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"
echo -e "| You                  | Rank  Opponent       | ${BLUE}Fights${NC}   | ${GREEN}Wins${NC}     | ${YELLOW}Draws${NC}    | ${RED}Defeats${NC}  | ${GREEN}Wins %${NC}   | ${YELLOW}Draws %${NC}  | ${RED}Def. %${NC}   | Trend    |"
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"
echo "$tab" | sort -i -r -t '|' -k 8
echo "+----------------------+----------------------+----------+----------+----------+----------+----------+----------+----------+----------+"

# echo -e ".width 25 25 7 5\nSELECT DISTINCT leek1, leek2, COUNT(leek1) as Combats, SUM(result) as Trend FROM fights WHERE leek1 = '$M' AND (context=2 OR context = 1) AND type=0 AND leek2 in ('$P1', '$P2', '$P3', '$P4', '$P5') GROUP BY leek1, leek2 ORDER BY leek1, 0.5+(Trend/Combats/2) DESC, Combats DESC;" | sqlite3 -header -column -batch lw.db


# Disconnect
curl -sS -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${token}" -X POST ${SITE}/farmer/disconnect >/dev/null

