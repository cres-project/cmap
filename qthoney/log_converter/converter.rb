#!/usr/bin/env ruby
# $Id$

require "open-uri"

require "rubygems"
require "json"

$KCODE = "u"

module QTHoney
   class Log2
      SEARCH_ENGINE_LIST_URL = "http://mew.ntcir.nii.ac.jp/qth_toolbar/qth_search_list.json"
      def initialize( io )
         cont = open( SEARCH_ENGINE_LIST_URL ){|http| http.read }
         @search_engine = JSON.parse( cont )
         @data = []
         io.each do |line|
            @data << JSON.parse( line )
         end
      end
      def convert
         http_req = {}
         actions = []
         @data.each do |e|
            # p e[ "eventType" ]
            # p e if e[ "eventType" ].nil? or  e[ "eventType" ] == "error"
            case e[ "eventType" ]
            when "init_qth"
               actions << {
                  :action => :start,
                  :timestamp => e[ "timestamp" ],
                  :tab_id => e[ "tab_id" ],
               }
            when "command"
               case e[ "target_id" ]
               when "LogTB-Pause-Button"
                  actions << {
                     :action => :end,
                     :timestamp => e[ "timestamp" ],
                     :tab_id => e[ "tab_id" ],
                     :page_id => e[ "page_id" ],
                     :url => e[ "url" ],
                     :title => e[ "title" ],
                     :page_type => url_page_type( e[ "url" ] ),
                  }
               end
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

      def url_page_type( url )
         @search_engine.each do |engine|
            if Regexp.new( engine[ "base_url" ] ) =~ url
               return {
                  :type => :serp,
               }
            end
         end
         { :type => :non_serp }
      end
   end
end

if $0 == __FILE__
   require "pp"
   log = QTHoney::Log2.new( ARGF )
   pp log.convert
end
