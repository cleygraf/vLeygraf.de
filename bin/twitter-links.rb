#!/usr/bin/ruby
# encoding: utf-8

require 'rubygems'
require 'csv'
require 'unshorten'
require 'json'
require 'digest/md5'
require 'faster_csv'

# Filenames
twitterlinks = "#{File.expand_path File.dirname(__FILE__)}/../tmp/twitter-links.txt"
linksjsonfile = "#{File.expand_path File.dirname(__FILE__)}/../tmp/links.json"
unshortenjsonfile = "#{File.expand_path File.dirname(__FILE__)}/../tmp/unshortencache.json"

linksperpage = 15

unshorturls = Hash[]
tweets = Hash[]

unshorturls = JSON.parse(File.read("#{unshortenjsonfile}"))
tweets = JSON.parse(File.read("#{linksjsonfile}"))

FasterCSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto, :encoding => "UTF-8") do |row|
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
			tweets["#{timestamp}"] = Hash[]
			tweets["#{timestamp}"]["URL"] = "#{linkurl}"
			tweets["#{timestamp}"]["TEXT"] = "#{linktext}"
            if linkurl =~ /http[s]*:\/\/([^/])*\/.*/i
                puts $1
            else
                puts "Parsing failed for link \"#{linkurl}\""
            end
    		else
                puts "Failed to parse this tweet: \"#{tweettext]\""
            end
		end
	end 
end

File.open("#{unshortenjsonfile}", 'w') { |io| io.puts unshorturls.to_json }
File.open("#{linksjsonfile}", 'w') { |io| io.puts tweets.to_json }

lasttsdate = ""
dailycount = 0
allcount = 0
allpagecount = 0
linknum = tweets.size
pagenum = (linknum / linksperpage.to_f).ceil
tweets.keys.sort.map do |ts,t|
	if ts =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)/ then
		tsdate = "#{$3}.#{$2}.#{$1}"
	else
		next
	end
    if allcount == 0 then
    	if lasttsdate != "" then
			ALLFILE.write("</ul>\n")
            ALLFILE.write("<div class=\"hnavigation\"><ul>\n")
            c = pagenum
            begin
    			if c == allpagecount then
    		        ALLFILE.write("&nbsp<li>#{c}</li>\n")
    			else
    			    ALLFILE.write("&nbsp<li><a href='/generated/alle_fundstuecke-#{c}/'>#{c}</a></li>\n")
    			end
                c -= 1
		    end until c == 0
            ALLFILE.write("</ul>\n")
			ALLFILE.close unless ALLFILE == nil
		end
        allpagecount = allpagecount + 1
    	Object.class_eval{remove_const :ALLOUTFILE} if defined?(ALLOUTFILE)
		ALLOUTFILE = "#{File.expand_path File.dirname(__FILE__)}/../content/generated/alle_fundstuecke-#{allpagecount}.html"
		Object.class_eval{remove_const :ALLFILE} if defined?(ALLFILE)
		ALLFILE = File.open("#{ALLOUTFILE}", "w")
    	ALLFILE.write("---\n")
    	ALLFILE.write("title: \"Alle Fundstücke (Seite #{allpagecount} von #{pagenum})\"\n")
    	ALLFILE.write("created_at: #{Date.today.to_s}\n")
    	ALLFILE.write("author: Christoph Leygraf\n")
    	ALLFILE.write("---\n")
    	ALLFILE.write("\n")
    	ALLFILE.write("<ul>\n")
    end
	if lasttsdate != tsdate then
        dailycount = 0 
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
    if dailycount == 3 then
        DAILYFILE.write("</ul>\n<!--break-->\nUnd noch mehr:\n<ul>\n")
    end
	DAILYFILE.write("<li><a href='#{tweets[ts]['URL']}'>#{tweets[ts]['TEXT']}</a></li>\n")
	lasttsdate = tsdate
    dailycount = dailycount + 1
    ALLFILE.write("<li><a href='#{tweets[ts]['URL']}'>#{tweets[ts]['TEXT']}</a></li>\n")
    allcount = allcount + 1
    if allcount >= linksperpage then
        allcount = 0;
    end
   
#   puts dailycount
#   puts "#{tsdate}"
end

ALLFILE.write("</ul>")
ALLFILE.close unless ALLFILE == nil

DAILYFILE.write("</ul>")
DAILYFILE.close unless DAILYFILE == nil

