#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id: ext-session.rb,v 1.1 2010/07/03 06:53:48 masao Exp $

# セッション単位でログデータを抽出する。

require "time"

def load_logdata( io = ARGF )
sessions = {}
ARGF.each do |line|
   actionid, userid, userip, sesid, lang, query, action, colid, nrrecords, recordpos, sboxid, objurl, time = line.chomp.split( /\t/ )
   if sesid.empty? or sesid == "null"
      sesid = userip
   end
   sessions[ sesid ] ||= []
   sessions[ sesid ] << [ actionid, userid, userip, sesid, lang, query, action, colid, nrrecords, recordpos, sboxid, objurl, time ]
end

STDERR.puts "Session size: #{ sessions.keys.size }"
sessions
end

if $0 == __FILE__
sessions = load_logdata

# session_keys = sessions.keys.sort_by{|e| sessions[e][0][12] }
# puts session_keys[ 0..20 ]
sessions.keys.each do |sesid|
   session = sessions[ sesid ]
   last_time = nil
   idx = 0
   session.each do |data|
      if last_time and Time.parse( data[12] ) > ( last_time + 1800 )
	 idx += 1
      end
      data[ 3 ] = "#{ sesid }-#{ idx }"
      last_time  = Time.parse( data[12] )
      puts data.join( "\t" )
   end
end

end
