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
linksbyhostname = Hash[]
linksbytag = Hash[]

taggedlinksnum = 0

unshorturls = JSON.parse(File.read("#{unshortenjsonfile}"))
#tweets = JSON.parse(File.read("#{linksjsonfile}"))

FasterCSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto, :encoding => "UTF-8") do |row|
#CSV.foreach("#{twitterlinks}", :quote_char => '"', :col_sep =>',', :row_sep =>:auto, :encoding => "UTF-8") do |row|
	if row[0] != "ID" then
		tweetid = row[0]
		timestamp = row[1]
		tweettext = row[3]
		if timestamp =~ /\A(\d\d\d\d-\d\d-\d\d)/ then
			tweetdate = $1
		end
		if ! tweets["#{timestamp}"] then
			if tweettext =~ /\A"*LINK:\s*(.*\S)\s*https*:\/\/(.*)\s*$/i
				linktext = $1
				linkshorturl = $2 		# without leading https:// oder http://
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
				linktext.scan(/#([A-Za-z0-9]+)/).flatten.each do | tag | 
					linksbytag["#{tag}"] = Hash[] if ! linksbytag["#{tag}"]
					linksbytag["#{tag}"]["#{timestamp}"] = "#{linktext}: #{linkurl}"
					taggedlinksnum += 1
				end
				linktext = linktext.gsub(/(#[A-Za-z0-9]+)/, '')
				tweets["#{timestamp}"] = Hash[]
				tweets["#{timestamp}"]["URL"] = "#{linkurl}"
				tweets["#{timestamp}"]["TEXT"] = "#{linktext}"
	            if linkurl =~ /https*:\/\/([a-zA-Z0-9\.-]*)\/.*/
	            	linkhostname = $1
			linksbyhostname["#{linkhostname}"] = Hash[] if ! linksbyhostname["#{linkhostname}"]
	            	linksbyhostname["#{linkhostname}"]["#{timestamp}"] = "#{linktext}: #{linkurl}"
	            else
	                puts "Parsing failed for link \"#{linkurl}\""
	            end
    		else
                puts "Failed to parse this tweet: \"#{tweettext}\""
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
linksperpagecorrection = 0
linknum = tweets.size
pagenum = (linknum / linksperpage.to_f).ceil
tweets.keys.sort.reverse.map do |ts,t|
	if ts =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)/ then
		tsdate = "#{$3}.#{$2}.#{$1}"
	else
		next
	end
	if allcount == 0 then
		if lasttsdate != "" then
			ALLFILE.write("</ul><!-- /list of timestamps -->\n")
			ALLFILE.write("<div class=\"hnavigation\"><!-- .hnavigation -->\n<ul><!-- pages -->\n")
			c = pagenum
			begin
				if c == allpagecount then
				ALLFILE.write("&nbsp<li>#{c}</li>\n")
				else
				    ALLFILE.write("&nbsp<li><a href='/generated/alle_fundstuecke-#{c}/'>#{c}</a></li>\n")
				end
				c -= 1
			end until c == 0
			ALLFILE.write("</div><!-- /.hnavigation -->\n</ul><!-- /pages -->\n")
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
		ALLFILE.write("<ul><!-- list of timestamps -->\n")
		if lasttsdate == tsdate then
			ALLFILE.write("<li>#{tsdate} Fortsetzung</li>\n<ul><!-- list of links per timestamp -->\n")
		end
 	end
	# new timestamp
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
		ALLFILE.write("</ul><!-- /list of links per timestamp -->\n") if allcount != 0
		ALLFILE.write("<li>#{tsdate}</li>\n<ul><!-- list of links per timestamp -->\n")
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
		ALLFILE.write("</ul><!-- /list of links per timestamp -->\n")
		allcount = 0;
	end
end

ALLFILE.write("</ul>")
ALLFILE.close unless ALLFILE == nil

DAILYFILE.write("</ul>")
DAILYFILE.close unless DAILYFILE == nil

#
# Create list of all links sorted and grouped by website
#
lasthostname = ""
hostnamelinecount = 0
hostnamepagecount = 0
linksperpagecorrection = 0
hostnamelinenum = linksbyhostname.size + tweets.size
hostnamepagenum = (hostnamelinenum / linksperpage.to_f).ceil
linksbyhostname.keys.sort.map do |host,v|
	linksbyhostname[host].keys.map do |ts,w|
        if hostnamelinecount == 0 then
            	if hostnamepagecount != 0 then
			HOSTNAMEFILE.write("</ul>\n")
			HOSTNAMEFILE.write("<div class=\"hnavigation\"><ul>\n")
			c = hostnamepagenum
			begin
				if c == hostnamepagecount then
			        	HOSTNAMEFILE.write("&nbsp<li>#{c}</li>\n")
			 	else
			 		HOSTNAMEFILE.write("&nbsp<li><a href='/generated/fundstuecke-website-#{c}/'>#{c}</a></li>\n")
			 	end
				c -= 1
			end until c == 0
			HOSTNAMEFILE.write("</ul></div>\n")
			HOSTNAMEFILE.close unless HOSTNAMEFILE == nil
    		end
            	hostnamepagecount += 1
        	Object.class_eval{remove_const :HOSTNAMEOUTFILE} if defined?(HOSTNAMEOUTFILE)
    		HOSTNAMEOUTFILE = "#{File.expand_path File.dirname(__FILE__)}/../content/generated/fundstuecke-website-#{hostnamepagecount}.html"
    		Object.class_eval{remove_const :HOSTNAMEFILE} if defined?(HOSTNAMEFILE)
    		HOSTNAMEFILE = File.open("#{HOSTNAMEOUTFILE}", "w")
        	HOSTNAMEFILE.write("---\n")
        	HOSTNAMEFILE.write("title: \"Alle Fundstücke nach Website (Seite #{hostnamepagecount} von #{hostnamepagenum})\"\n")
        	HOSTNAMEFILE.write("created_at: #{Date.today.to_s} #{Time.now.to_s}\n")
        	HOSTNAMEFILE.write("author: Christoph Leygraf\n")
        	HOSTNAMEFILE.write("---\n")
        	HOSTNAMEFILE.write("\n")
        	HOSTNAMEFILE.write("<ul>\n")
        end
		if lasthostname != host
			HOSTNAMEFILE.write("</ul>\n") if lasthostname != ""
			HOSTNAMEFILE.write("<li><a href='http://#{host}'>#{host}</a></li>\n<ul>\n")
            		hostnamelinecount += 1
		end
		HOSTNAMEFILE.write("<li><a href='#{tweets[ts]['URL']}'>#{tweets[ts]['TEXT']}</a></li>\n")
		hostnamelinecount += 1
		lasthostname = host
        	if hostnamelinecount >= linksperpage + linksperpagecorrection
			linksperpagecorrection = linksperpage - hostnamelinecount + linksperpagecorrection
            		HOSTNAMEFILE.write("</ul>\n")
            		lasthostname = ""
            		hostnamelinecount = 0
		end
	end
end

HOSTNAMEFILE.write("</ul>")
HOSTNAMEFILE.write("</ul>")
HOSTNAMEFILE.write("<div class=\"hnavigation\"><ul>\n")
c = hostnamepagenum
begin
	if c == hostnamepagecount then
		HOSTNAMEFILE.write("&nbsp<li>#{c}</li>\n")
	else
		HOSTNAMEFILE.write("&nbsp<li><a href='/generated/fundstuecke-website-#{c}/'>#{c}</a></li>\n")
	end
	c -= 1
end until c == 0
HOSTNAMEFILE.write("</ul></div>\n")
HOSTNAMEFILE.close unless HOSTNAMEFILE == nil

#
# Create list of all tags and the corresponding links
#
lasttag = ""
taglinecount = 0
tagpagecount = 0
linksperpagecorrection = 0
taglinenum = linksbytag.size + taggedlinksnum
tagpagenum = (taglinenum / linksperpage.to_f).ceil
linksbytag.keys.sort_by { |tag| -linksbytag[tag].size}.each do |tag|
	linksbytag[tag].keys.map do |ts,w|
        if taglinecount == 0 then
            	if tagpagecount != 0 then
			TAGFILE.write("</ul>\n")
			TAGFILE.write("<div class=\"hnavigation\"><ul>\n")
			c = tagpagenum
			begin
				if c == tagpagecount then
			        	TAGFILE.write("&nbsp<li>#{c}</li>\n")
			 	else
			 		TAGFILE.write("&nbsp<li><a href='/generated/tags-#{c}/'>#{c}</a></li>\n")
			 	end
				c -= 1
			end until c == 0
			TAGFILE.write("</ul></div>\n")
			TAGFILE.close unless TAGFILE == nil
    		end
            	tagpagecount += 1
        	Object.class_eval{remove_const :TAGOUTFILE} if defined?(TAGOUTFILE)
    		TAGOUTFILE = "#{File.expand_path File.dirname(__FILE__)}/../content/generated/tags-#{tagpagecount}.html"
    		Object.class_eval{remove_const :TAGFILE} if defined?(TAGFILE)
    		TAGFILE = File.open("#{TAGOUTFILE}", "w")
        	TAGFILE.write("---\n")
        	TAGFILE.write("title: \"Tags und die zugehörigen Fundstücke (Seite #{tagpagecount} von #{tagpagenum})\"\n")
        	TAGFILE.write("created_at: #{Date.today.to_s} #{Time.now.to_s}\n")
        	TAGFILE.write("author: Christoph Leygraf\n")
        	TAGFILE.write("---\n")
        	TAGFILE.write("\n")
        	TAGFILE.write("<ul>\n")
        end
		if lasttag != tag
			TAGFILE.write("</ul>\n") if lasttag != ""
			TAGFILE.write("<li><a href='http://#{tag}'>#{tag}</a></li>\n<ul>\n")
            		taglinecount += 1
		end
		TAGFILE.write("<li><a href='#{tweets[ts]['URL']}'>#{tweets[ts]['TEXT']}</a></li>\n")
		taglinecount += 1
		lasttag = tag
        	if taglinecount >= linksperpage + linksperpagecorrection
			linksperpagecorrection = linksperpage - taglinecount + linksperpagecorrection
            		TAGFILE.write("</ul>\n")
            		lasttag = ""
            		taglinecount = 0
		end
	end
end

TAGFILE.write("</ul>")
TAGFILE.write("</ul>")
TAGFILE.write("<div class=\"hnavigation\"><ul>\n")
c = tagpagenum
begin
	if c == tagpagecount then
		TAGFILE.write("&nbsp<li>#{c}</li>\n")
	else
		TAGFILE.write("&nbsp<li><a href='/generated/tags-#{c}/'>#{c}</a></li>\n")
	end
	c -= 1
end until c == 0
TAGFILE.write("</ul></div>\n")
TAGFILE.close unless TAGFILE == nil
