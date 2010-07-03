#!/usr/bin/env ruby
# $Id: ext-log2tsv.rb,v 1.2 2010/07/03 04:19:48 masao Exp $

ARGF.each do |line|
   if line =~ /\A(\w+);(\w+);([^;]*);([^;]*);([^;]*);(.*?);([\w\/]*);([^;]*?);([^;]*?);([^;]*?);(.*?);(.*?);([^;]*?)\Z/
      actionid = $1
      userid   = $2
      userip   = $3
      sesid    = $4
      lang     = $5
      query    = $6
      action   = $7
      colid    = $8
      nrrecords= $9
      recordpos= $10
      sboxid   = $11
      objurl   = $12
      time     = $13
      puts [
            actionid,
            userid  ,
            userip  ,
            sesid   ,
            lang    ,
            query.to_s.gsub( /\t/, " " ),
            action  ,
            colid   ,
            nrrecords,
            recordpos,
            sboxid  ,
            objurl  ,
            time ].join( "\t" )
   else
      raise "#$.:#{ line }"
   end
end
