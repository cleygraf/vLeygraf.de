#!/usr/bin/ruby
# encoding: utf-8

require 'rubygems'
require 'csv'
require 'unshorten'
require 'json'
require 'digest/md5'

# Filenames
twitterlinks = "#{File.expand_path File.dirname(__FILE__)}/../tmp/twitter-links.txt"
linksjsonfile = "#{File.expand_path File.dirname(__FILE__)}/../tmp/links.json"
unshortenjsonfile = "#{File.expand_path File.dirname(__FILE__)}/../tmp/unshortencache.json"

unshorturls = Hash[]
tweets = Hash[]

unshorturls = JSON.parse(File.read("#{unshortenjsonfile}"))
tweets = JSON.parse(File.read("#{linksjsonfile}"))

CSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|
	if row[0] != "ID" then
		tweetid = row[0]
		timestamp = row[1]
		tweettext = row[3]
		if timestamp =~ /\A(\d\d\d\d-\d\d-\d\d)/ then
			tweetdate = $1
		end
		if ! tweets["#{timestamp}"] then
			if tweettext =~ /\A"*LINK:\s*(.*\S)\s*(https*:\/\/.*)\s*$/i
				linktext = $1
				linkshorturl = $2
				if ! unshorturls["#{linkshorturl}"] then
					linkurl = Unshorten["#{linkshorturl}"]
					if linkurl != linkshorturl then
						unshorturls["#{linkshorturl}"] = "#{linkurl}"
					else
						puts "Failed to unshorten \"#{linkshorturl}\" -> \"#{linkurl}\"" 
					end
				else
					linkurl = unshorturls["#{linkshorturl}"]
				end
			end
			tweets["#{timestamp}"] = Hash[]
			tweets["#{timestamp}"]["URL"] = "#{linkurl}"
			tweets["#{timestamp}"]["TEXT"] = "#{linktext}"
		end
	end 
end

File.open("#{unshortenjsonfile}", 'w') { |io| io.puts unshorturls.to_json }
File.open("#{linksjsonfile}", 'w') { |io| io.puts tweets.to_json }

lasttsdate = ""
tweets.keys.sort.map do |ts,t|
	if ts =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)/ then
		tsdate = "#{$3}.#{$2}.#{$1}"
	else
		next
	end
	if lasttsdate != tsdate then
		if lasttsdate != "" then
			DAILYFILE.write("</ul>")
			DAILYFILE.close unless DAILYFILE == nil
		end
		Object.class_eval{remove_const :DAILYOUTFILE} if defined?(DAILYOUTFILE)
		DAILYOUTFILE = "#{File.expand_path File.dirname(__FILE__)}/../content/generated/fundstuecke_#{tsdate}.html"
		Object.class_eval{remove_const :DAILYFILE} if defined?(DAILYFILE)
		DAILYFILE = File.open("#{DAILYOUTFILE}", "w")
		DAILYFILE.write("---\n")
		DAILYFILE.write("kind: article\n")
		DAILYFILE.write("title: \"Fundstücke vom #{tsdate}\"\n")
		DAILYFILE.write("created_at: #{ts}\n")
		DAILYFILE.write("author: Christoph Leygraf\n")
		DAILYFILE.write("---\n")
		DAILYFILE.write("\n")
		DAILYFILE.write("<ul>\n")
	end
	DAILYFILE.write("<li><a href='#{tweets[ts]['URL']}'>#{tweets[ts]['TEXT']}</a></li>\n")
	lasttsdate = tsdate
#  	puts "#{tsdate}"
end