#!/bin/bash
#
# requires t and unshorten gem
#

execpath=$(dirname $0)
infile="$execpath/../tmp/twitter-links.txt"

# Path to "t" command
if [ -x '/var/lib/gems/1.8/bin/t' ]; then t_command="/var/lib/gems/1.8/bin/t"
elif [ -x '/usr/bin/t' ]; then t_command="/usr/bin/t"
else
	echo "\"t\" command not found" 
	exit
fi
echo "Using \"$t_command\""
echo ""

# Fetch all my tweets startin containing "LINK:"
old_tweetcount=$(cat $infile | wc -l)
echo -n "Fetching tweets ... " && $t_command search timeline "LINK:" -l -N --csv >> $infile
echo -n "finished\n"
echo -n "Parsing tweets ... "
/usr/bin/sort -ru $infile -o $infile
new_tweetcount=$(cat $infile | wc -l)
let tweetdelta=$new_tweetcount-$old_tweetcount
echo -n "finished\n"
echo "$tweetdelta new tweets"
