#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# count su number in each session


sessions = {}
ARGF.each do |line|
   actionid, userid, userip, sesid, lang, query, action, colid, nrrecords, recordpos, sboxid, objurl, time = line.chomp.split( /\t/ )
   sessions[ sesid ] ||= []
   sessions[ sesid ] << line.chomp.split( /\t/ )
end

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
