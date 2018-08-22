# Jukebox

Home made jukebox over streaming.


The jukebox is composed of a server component, currently in ruby, and a web client.
Please note that the website is directly hosted by the ruby application, no web server is required.

Web-client rely on HTML5 audio api, or flash, depending on your browser.
Client side pass jslint & ajaxmin checks.
A documentation is generated.

## Installation

The server installation is mandatory.
Web client installation is facultative (only if you wish to develop html/js).

* [Server installation tutorial](ServerInstallation)
* [Web client installation tutorial](gruntjs)

gem install rev sqlite3 rpam-ruby19 redmine_client bcrypt-ruby

gem install rainbow -v 2.2.2
gem install rubocop -v 0.50.0
gem install nokogiri -v 1.6.8.1
gem install ruby-debug-ide
gem install debase
gem install ruby-lint
gem install reek -v 3.11
gem install fasterer
gem install rcodetools fastri

youtube-dl https://www.youtube.com/watch?v=Mfm0FTMmwxw -x --audio-format mp3 --add-metadata -o "%(id)s.%(ext)s"

## Start/Stop the server

Start:

	ruby jukebox.rb

Stop:

	Ctrl + C

## Listen

From a browser:

	http://<host>:<port>/

See your jukebox.cfg for port.

From any player:

	http://<host>:<port>/stream

With credentials:

	http://user:pass@<host>:<port>/stream
