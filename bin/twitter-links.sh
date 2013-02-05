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

# Path to "unshorten" command
if [ -x '/var/lib/gems/1.8/bin/unshorten' ]; then unshorten_command="/var/lib/gems/1.8/bin/unshorten"
elif [ -x '/usr/bin/unshorten' ]; then unshorten_command="/usr/bin/unshorten"
else
	echo "\"unshorten\" command not found" 
	exit
fi
echo "Using \"$unshorten_command\""

echo ""

# Fetch all my tweets startin containing "LINK:"
old_tweetcount=$(cat $infile | wc -l)
#$t_command search timeline "LINK:" -l -N --csv >> $infile
/usr/bin/sort -u $infile -o $infile
new_tweetcount=$(cat $infile | wc -l)
let tweetdelta=$new_tweetcount-$old_tweetcount
echo "$tweetdelta new tweets"

echo ""

# Create filter from 1st parameter 
if [ "$#" -eq 0 ]; then
	datelist="$(grep -v "^ID" $infile|awk -F',' '{ print $2 }'|awk '{ print $1 }'|sort -u)"
else
	datelist="$1"
fi

for datefilter in $datelist; do
	echo "Parsing tweets from $datefilter"

	outfile="$execpath/../content/generated/fundstuecke_$datefilter.html"

	year=$(echo "$datefilter"|awk -F'-' '{ print $1 }')
	month=$(echo "$datefilter"|awk -F'-' '{ print $2 }')
	day=$(echo "$datefilter"|awk -F'-' '{ print $3 }')


	# Matching tweets for today?
	if [ "$(grep "$datefilter" $infile|wc -l|awk '{ print $1 }')" != "0" ]; then

		# Create list of links
		echo "---" > "$outfile"
		echo "kind: article" >> "$outfile"
		echo "title: \"Fundstücke vom $day.$month.$year\"" >> "$outfile"
		echo "created_at: $datefilter" >> "$outfile"
		echo "author: Christoph Leygraf" >> "$outfile"
		echo "---" >> "$outfile"
		echo "" >> "$outfile"

		#HTML-output
		echo "<ul>" >> "$outfile"

		count=0
		IFS_OLD=$IFS; IFS=$'\n'
		for i in $(cat $infile|grep "$datefilter"|awk -F',' '{for (i=4; i<NF; i++) printf $i " "; print $NF}'|sed 's/^"\(.*\)"$/\1/'|sed 's/.*LINK://')
		do
			description=$(echo $i|sed "s/\(.*\)http.*/\1/")			
			url=$(echo $i|sed "s/.*\(http.*\)/\1/")
			unshortenedurl=$($unshorten_command "$url")

			# HTML-output
			if [ $count -eq 3 ]; then echo -e "\n</ul>\n<!--break-->\nUnd noch mehr:\n<ul>\n" >> "$outfile"; fi
			echo "<li><a href='$unshortenedurl'>$description</a></li>" >> "$outfile"

			let count=count+1
		done
		IFS=IFS_OLD
		echo "</ul>" >> "$outfile"
	fi
done


#
# All links on some pages
#

echo ""
echo "Creating \"Alle Fundstuecke\""

# Create list of links
linksperpage=20
totallinks=$(grep -v "^ID" "$infile"|grep -v "^$"|wc -l)
echo "$totallinks links"
let totalpages=$totallinks/$linksperpage
let linkbase=$totalpages*$linksperpage
if [ $totallinks -gt $linkbase ]; then let totalpages=$totalpages+1; fi

lasttweetdate="$(grep -v "^ID" $infile|awk -F',' '{ print $2 }'|awk '{ print $1 }'|sort -u|tail -n 1)"
year=$(echo "$lasttweetdate"|awk -F'-' '{ print $1 }')
month=$(echo "$lasttweetdate"|awk -F'-' '{ print $2 }')
day=$(echo "$lasttweetdate"|awk -F'-' '{ print $3 }')
echo "Newest tweet from $year-$month-$day"

pagecount=1; linkcount=1
IFS_OLD=$IFS; IFS=$'\n'
for i in $(grep -v "^ID" $infile|grep -v "^$"|sed 1d|awk -F',' '{for (i=4; i<NF; i++) printf $i " "; print $NF}'|sed 's/^"\(.*\)"$/\1/'|sed 's/.*LINK://')
do
	if [ $linkcount -eq 1 ]; then
		echo "alle_fundstuecke-$pagecount"
		outfile="$execpath/../content/generated/alle_fundstuecke-$pagecount.html"
		echo "---" > "$outfile"
		# echo "kind: article" >> "$outfile"
		echo "title: \"Alle Fundstücke (Seite $pagecount von $totalpages)\"" >> "$outfile"
		echo "created_at: $year-$month-$day" >> "$outfile"
		echo "author: Christoph Leygraf" >> "$outfile"
		echo "---" >> "$outfile"
		echo "" >> "$outfile"
		echo "<ul>" >> "$outfile"
	fi

	description=$(echo $i|sed "s/\(.*\)http.*/\1/")
	url=$(echo $i|sed "s/.*\(http.*\)/\1/")
	unshortenedurl=$($unshorten_command "$url")
	echo "<li><a href='$unshortenedurl'>$description</a></li>" >> "$outfile"

	let linkcount=$linkcount+1
	if [ $linkcount -ge $linksperpage ]; then 
		echo "</ul>" >> "$outfile"
		echo "<div class=\"hnavigation\"><ul>" >> "$outfile"
		for (( c=$totalpages; c>0; c-- ))
		do
			if [ $c -eq $pagecount ]; then
				echo "&nbsp<li>$c</li>" >> "$outfile"
			else
				echo "&nbsp<li><a href='/generated/alle_fundstuecke-$c/'>$c</a></li> " >> "$outfile"
			fi
		done
		echo "</ul></div><!-- / .hnavigation -->" >> "$outfile"
		let pagecount=$pagecount+1
		linkcount=1;
	fi
done
IFS=IFS_OLD


if [ $linkcount -gt 1 ]; then
	echo "</ul>" >> "$outfile"
	echo "<div class=\"hnavigation\"><ul>" >> "$outfile"
	for (( c=$totalpages; c>0; c-- ))
	do
		if [ $c -eq $pagecount ]; then
			echo "&nbsp<li>$c</li>" >> "$outfile"
		else
			echo "&nbsp<li><a href='/generated/alle_fundstuecke-$c/'>$c</a></li> " >> "$outfile"
		fi
	done
	echo "</ul></div><!-- / .hnavigation -->" >> "$outfile"
fi