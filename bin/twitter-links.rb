#!/usr/bin/ruby

require 'rubygems'
require 'faster_csv'
require 'unshorten'

twitterlinks="#{File.expand_path File.dirname(__FILE__)}/../tmp/twitter-links.txt"

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
			linkurl = Unshorten["#{linkshorturl}"]
		end
		puts "#{tweetdate} #{linktext} -> \"#{linkurl}\""
	end 
 end