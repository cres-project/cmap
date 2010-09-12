#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# count su number in each session

$:.push File.dirname($0)
require "ext-session.rb"

sessions = load_logdata

sessions.keys.each do |sesid|
	session = sessions[ sesid ]
	i = 0
	cnt_su = 0
	while i < session.size do
		if /search_/ =~ session[ i ][ 6 ] then
	#		if /search_url/ =~ session[ i ][ 6 ] then
	#		else
				cnt_su = cnt_su + 1
	#		end
		end
		i = i + 1
	end
	puts [ sesid, cnt_su ].join( "\t" )
end
