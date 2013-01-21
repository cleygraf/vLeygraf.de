#!/usr/bin/ruby

require 'rubygems'
require 'faster_csv'
require 'unshorten'

twitterlinks="#{File.expand_path File.dirname(__FILE__)}/../tmp/twitter-links.txt"
unshortencachefile="#{File.expand_path File.dirname(__FILE__)}/../tmp/unshortencache.txt"
unshorturls = Hash[]

unshorturls = File.open("#{unshortencachefile}", "rb") {|io| Marshal.load(io)}

FasterCSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|
	if row[0] != "ID" then
		timestamp = row[1]
		tweettext = row[3]
		if timestamp =~ /\A(\d\d\d\d-\d\d-\d\d)/ then
			tweetdate = [$1]
		end
		if tweettext =~ /\A"*LINK:\s*(.*\S)\s*(https*:\/\/.*)\s*$/i
			linktext = [$1]
			linkshorturl = [$2]
			if ! unshorturls["#{linkshorturl}"] then
				linkurl = Unshorten["#{linkshorturl}"]
				unshorturls["#{linkshorturl}"] = "#{linkurl}"
			else
				linkurl = unshorturls["#{linkshorturl}"]
			end
		end
		puts "#{tweetdate} #{linktext} -> \"#{linkurl}\""
	end 
end

File.open("#{unshortencachefile}", "wb") {|io| Marshal.dump(unshorturls, io)}