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
		if /view_full/ =~ session[ i ][ 6 ] then
			print(sesid, "\t", session[i][9], "\n")
		end
		i = i + 1
	end
end
