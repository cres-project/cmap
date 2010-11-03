#!/usr/bin/env ruby
# $Id$

require "rubygems"
require "json"

$KCODE = "u"

module QTHoney
   class Log2
      def initialize( io )
         @data = []
         io.each do |line|
            @data << JSON.parse( line )
         end
      end
      http_req = {}
      def convert
         actions = []
         @data.each do |e|
            # p e[ "eventType" ]
            # p e if e[ "eventType" ].nil? or  e[ "eventType" ] == "error"
            case e[ "eventType" ]
            when "init_qth"
               actions << {
                  :action => :start,
                  :timestamp => e[ "timestamp" ],
                  # :tab_id => e[ "tab_id" ],
               }
            when "http_req"
               http_req[ ]
            when "pageshow"
               url = e[ "pageshow_url" ]
               actions << {
                  :action => :show,
                  :url => url,
                  :timestamp => e[ "timestamp" ]
               }
            end
         end
         actions
      end
   end
end

if $0 == __FILE__
   require "pp"
   log = QTHoney::Log2.new( ARGF )
   pp log.convert
end
