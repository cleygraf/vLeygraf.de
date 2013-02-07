#!/usr/bin/ruby

require 'rubygems'
require 'csv'
require 'unshorten'
require 'json'

twitterlinks="#{File.expand_path File.dirname(__FILE__)}/../tmp/twitter-links.txt"
unshortencachefile="#{File.expand_path File.dirname(__FILE__)}/../tmp/unshortencache.txt"
unshortenjsonfile="#{File.expand_path File.dirname(__FILE__)}/../tmp/unshortencache.json"
unshorturls = Hash[]
tweets = Hash[]

#unshorturls = File.open("#{unshortencachefile}", "rb") {|io| Marshal.load(io)}
unshorturls = JSON.parse(File.read("#{unshortenjsonfile}"))

CSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|
	if row[0] != "ID" then
		tweetid = row[0]
		timestamp = row[1]
		tweettext = row[3]
		if timestamp =~ /\A(\d\d\d\d-\d\d-\d\d)/ then
			tweetdate = [$1]
		end
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
		tweets["#{tweetid}"] = Hash[]
		tweets["#{tweetid}"]["URL"] = "#{linkurl}"
#		puts "#{tweetdate} #{linktext} -> \"#{linkurl}\" (\"#{linkshorturl}\")"
	end 
end

#File.open("#{unshortencachefile}", "wb") {|io| Marshal.dump(unshorturls, io)}
File.open("#{unshortenjsonfile}", 'w') { |io| io.puts unshorturls.to_json }