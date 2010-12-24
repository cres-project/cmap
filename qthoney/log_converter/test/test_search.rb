#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestSearch < Test::Unit::TestCase
      LOG_TEST = File.join( File.dirname( __FILE__ ), "test-17.log" )

      def test_search
         open( LOG_TEST ) do |io|
            logdata = Log2.new( io ).convert
            assert( logdata )
            assert( logdata.size > 0 )
            assert( logdata.first )

            search_actions = logdata.select{|e| e[ :action ] == :search }
            assert_equal( 1, search_actions.size,
                          "one single search action should be recorded." )
            search_actions.each do |action|
               [ :timestamp, :tab_id, :page_id, :url, :page_type, :title,
                 :anchor_text, :target_url,
                 # TODO: :target_page_id, :target_tab_id,
               ].each do |attr|
                  assert( action.key?( attr ), "no #{ attr } at search action." )
               end
            end
         end
      end
   end
end
