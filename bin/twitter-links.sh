#!/bin/bash
#
# requires t and unshorten gem
#

execpath=$(dirname $0)
infile="$execpath/../tmp/twitter-links.txt"

# Path to "t" command
if [ -x '/var/lib/gems/1.8/bin/t' ]; then t_command="/var/lib/gems/1.8/bin/t"
elif [ -x '/usr/bin/t' ]; then t_command="/usr/bin/t"
else exit
fi

# Path to "unshorten" command
if [ -x '/var/lib/gems/1.8/bin/unshorten' ]; then unshorten_command="/var/lib/gems/1.8/bin/unshorten"
elif [ -x '/usr/bin/unshorten' ]; then unshorten_command="/usr/bin/unshorten"
else exit
fi

# Fetch all my tweets startin containing "LINK:"
#$t_command search timeline "LINK:" -l -N --csv > $infile 

# Create filter from 1st parameter 
if [ "$#" -eq 0 ]; then
	datelist="$(cat $infile|awk -F',' '{ print $2 }'|awk '{ print $1 }'|tail -n +2|uniq)"
else
	datelist="$1"
fi

for datefilter in $datelist; do
	
	outfile="$execpath/../content/blog/cleygraf/fundstuecke_$datefilter.html"

	year=$(echo "$datefilter"|awk -F'-' '{ print $1 }')
	month=$(echo "$datefilter"|awk -F'-' '{ print $2 }')
	day=$(echo "$datefilter"|awk -F'-' '{ print $3 }')


	# Matching tweets for today?
	if [ "$(wc -l $infile|grep "$datefilter"|awk '{ print $1 }')" != "0" ]; then

		# Create list of links
		echo "---" > "$outfile"
		echo "kind: article" >> "$outfile"
		echo "title: Fundstücke vom $day.$month.$year" >> "$outfile"
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