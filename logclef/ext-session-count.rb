#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id: ext-session-counttime.rb,v 1.1 2010/07/03 06:53:48 masao Exp $

# セッション単位でログデータを抽出する。

$:.push File.dirname($0)
require "ext-session.rb"

sessions = load_logdata

# session_keys = sessions.keys.sort_by{|e| sessions[e][0][12] }
# puts session_keys[ 0..20 ]
sessions.keys.each do |sesid|
   session = sessions[ sesid ]
   if session.size == 1
      time = 0 
   else 
      last_time  = Time.parse( session[ -1][12] )
      first_time = Time.parse( session[ 0 ][12] )
      time = ( last_time - first_time ).to_i
   end
   puts [ sesid, session.size, time ].join( "\t" )
end
