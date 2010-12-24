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
         pre_action = {}
         link_background = {}
         actions = []
         @data.each do |e|
            pre_action[ e[ "tab_id" ] ] ||= [] if e[ "tab_id" ] and not e[ "tab_id" ].empty?
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
                     :page_type => url_page_type( e[ "url" ] )[ :type ],
                  }
               when "cmd_quitApplication"
                  pre_action[ :cmd_quitApplication ] = {
                     :action => :end,
                     :timestamp => e[ "timestamp" ],
                     :tab_id => e[ "tab_id" ],
                     :page_id => e[ "page_id" ],
                     :url => e[ "url" ],
                     :title => e[ "title" ],
                     :page_type => url_page_type( e[ "url" ] )[ :type ],
                  }
               end
            when "onCloseWindow"
               if pre_action[ :cmd_quitApplication ]
                  actions << pre_action[ :cmd_quitApplication ]
               else
                  actions << {
                     :action => :end,
                     :timestamp => e[ "timestamp" ],
                     :tab_id => e[ "tab_id" ],
                     :page_id => e[ "page_id" ],
                     :url => e[ "url" ],
                     :title => e[ "title" ],
                     :page_type => url_page_type( e[ "url" ] )[ :type ],
                  }
               end
            when "http_req"
               url = e[ "requestURI" ]
               load_data = {
                  :action => :load,
                  :timestamp => e[ "timestamp" ],
                  :tab_id => e[ "tab_id" ],
                  :page_id => e[ "page_id" ],
                  :url => url,
                  :title => e[ "title" ],
                  :page_type => url_page_type( url )[ :type ],
               }
               http_req[ url ] = load_data
            when "pageshow"
               url = e[ "pageshow_url" ]
               next if url == "about:blank"
               if http_req[ url ]
                  http_req[ url ][ :title ] = e[ "title" ]
                  http_req[ url ][ :page_id ] = e[ "page_id" ]
                  actions << http_req[ url ]
                  http_req.delete( url )
               end
               if not link_background[ url ]
                  actions << {
                     :action => :show,
                     :timestamp => e[ "timestamp" ],
                     :tab_id => e[ "tab_id" ],
                     :page_id => e[ "page_id" ],
                     :url => url,
                     :title => e[ "title" ],
                     :page_type => url_page_type( url )[ :type ],
                  }
               else
                  link_background.delete( url )
               end
            when "TabSelect"
               actions << {
                  :action => :change,
                  :timestamp => e[ "timestamp" ],
                  :tab_id => e[ "tab_id" ],
                  :page_id => e[ "page_id" ],
                  :url => e[ "url" ],
                  :title => e[ "title" ],
                  :page_type => url_page_type( url )[ :type ],
               }
               actions << {
                  :action => :show,
                  :timestamp => e[ "timestamp" ],
                  :tab_id => e[ "tab_id" ],
                  :page_id => e[ "page_id" ],
                  :url => e[ "url" ],
                  :title => e[ "title" ],
                  :page_type => url_page_type( url )[ :type ],
               }
            end
            case e[ "event_label" ]
            when "click"
               if not e[ "target" ] =~ /object (XULElement|XPCNativeWrapper)/
                  actions << {
                     :action => :link,
                     :timestamp => e[ "timestamp" ],
                     :tab_id => e[ "tab_id" ],
                     :page_id => e[ "page_id" ],
                     :url => url,
                     :title => e[ "title" ],
                     :page_type => url_page_type( url )[ :type ],
                     :anchor_text => anchor_text( e[ "anchor_outerHTML" ] ),
                     :target_url => e[ "target" ],
                     # TODO: target_page_id, target_tab_id
                  }
                  if e[ "modifiers" ][ "ctrl" ] == true
                     link_background[ e["target"] ] = true
                  end
               end
            end
            pre_action[ e[ "tab_id" ] ] << e if e[ "tab_id" ] and not e[ "tab_id" ].empty?
         end
         actions
      end

      def to_tsv
         self.convert.map do |d|
            [ :timestamp,
              :action, :tab_id, :page_id, :url, :title, :page_type,
              :searchengine_label, :query, :serp_page, :anchor_text,
              :target_url, :target_searchengine_label, :target_query,
              :target_serp_page, :target_page_id, :target_tab_id,
              :bookmark_title, :target_object, :form_values ].map do |e|
               d[ e ]
            end.join( "\t" )
         end
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
      def anchor_text( html )
         if html.nil?
            ""
         else
            html.gsub( /\A\s*<a[^>]*>(.*)<\/a>\s*\Z/i ){
               $1
            }.gsub( /<img([^>]*)>/i ){
               attrs = $1
               if attrs =~ /alt\s*=\s*(["']?)(.*?)\1/i
                  $2
               elsif attrs =~ /title\s*=\s*(["']?)(.*?)\1/i
                  $2
               else
                  "[img]"
               end
            }.gsub( /<\/?\w+[^>]*>/, "" )
         end
      end
   end
end

if $0 == __FILE__
   require "pp"
   log = QTHoney::Log2.new( ARGF )
   pp log.convert
   puts "----"
   puts log.to_tsv
end
