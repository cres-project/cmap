#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id: ext-session-split.rb,v 1.3 2010/07/03 07:17:08 masao Exp $

# セッション単位でログデータを抽出する。

require "./ext-session.rb"

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

