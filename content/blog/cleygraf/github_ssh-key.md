---
title:  Extra SSH-Key für git verwenden
kind: article
created_at: 2013-01-08 22:40
author: Christoph Leygraf
---

Auf meinem Webserver möchte ich automatisch per `git pull` Aktualisierungen meiner Website aus dem Repository bei Github übernehmen können. Standardmäßig greift das `git`-Kommando dabei auf den SSH-Key `~/.ssh/id_rsa` zurück, bei dessen Nutzung bei mir natürlich die Eingabe einer Passphrase verlangt wird. Dies ist bei einem automatischen Prozess, z. B. per `cron`, nicht praktikabel.<!--break--> Darum nutze ich nur für diese Verwendung einen extra SSH-Key ohne Passphrase nur zum Zugriff auf Github. Welcher SSH-Key jeweils zum Einsatz kommt,  kann in `~/.ssh/config` gesteuert werden:

	Host github.com
	Hostname github.com
	User git
	IdentityFile ~/.ssh/id_rsa-github-www
	IdentitiesOnly yes

Entgegen anderslautender Beschreibungen, muss hier bei „`Host`“ der Domainname „`github.com`“ angegeben werden, ebenso wie bei „`Hostname`“.