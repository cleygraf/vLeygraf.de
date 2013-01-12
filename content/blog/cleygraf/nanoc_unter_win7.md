---
title:  nanoc unter Windows 7
kind: article
created_at: 2013-01-12
author: Christoph Leygraf
---

Möchte man Ruby unter Windows nutzen, so bietet sich dafür [cygwin](http://www.cygwin.com/) an. [Diese Seite](http://recurial.com/programming/set-up-a-rails-3-development-environment-in-windows-with-cygwin/) hat mir dabei geholfen, Ruby auf meinem Dienstlaptop zum Laufen zu bekommen.

Sind die RubyGems einmal installiert, ist mit `gem install nanoc` die Einrichtung z.B. von nanoc ein Kinderspiel:

	cleygraf@tpcleygraf ~/dev/vLeygraf.de
	$ gem install nanoc
	Fetching: nanoc-3.4.3.gem (100%)
	Successfully installed nanoc-3.4.3
	1 gem installed
	Installing ri documentation for nanoc-3.4.3...
	Installing RDoc documentation for nanoc-3.4.3...
	cleygraf@tpcleygraf ~/dev/vLeygraf.de
	$ 

Bei mir trat jedoch als erstes immer wieder folgender Fehler auf:

	...

	Message:
	
	Encoding::CompatibilityError: incompatible character encodings: CP850 and UTF-8

	...
	
Nach einigem Googeln bin ich auf eine Lösung dafür gestoßen:

	/cygdrive/c/Windows/SysWOW64/chcp.com 65001
	
Wenn ich Putty verwende, um mich per SSH mit dem Windows7-System zu verbinden, dann muss ich dieses Kommando in jeder Sitzung erneut augeführen. Führe ich `nanoc` jedoch lokal in einer RXVT-Sitzung aus, treten die "`incompatible character encodings`"-Probleme nicht auf.

Dafür macht mir eine zweite Fehlermeldung das Leben schwer:

	$ nanoc compile
	Loading site dataâ€¦
	Compiling siteâ€¦
	/usr/lib/ruby/gems/1.9.1/gems/nanoc-3.4.3/lib/nanoc/base/memoization.rb:55: stack level too deep (SystemStackError)
	
Vor dem `nanoc compile` ein `rm -fR ./output` abgesetzt, und  auch dieses Problem ist zum Glück gelöst.
