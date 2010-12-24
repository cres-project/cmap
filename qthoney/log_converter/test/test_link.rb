#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestLink < Test::Unit::TestCase
      LOG_TEST = 

      def test_link
         {  "test-12.log" => 1,
            "test-13.log" => 3,
            "test-14.log" => 1,
            "test-15.log" => 1,
            "test-16.log" => 1,
         }.each do |file, linkcount|
            open( File.join( File.dirname( __FILE__ ), file ) ) do |io|
               logdata = Log2.new( io ).convert
               assert( logdata )
               assert( logdata.size > 0 )
               assert( logdata.first )

               link_actions = logdata.select{|e| e[ :action ] == :link }
               assert_equal( linkcount, link_actions.size )
               link_actions.each do |action|
                  [ :timestamp, :tab_id, :page_id, :url, :page_type, :title,
                    :anchor_text, :target_url,
                    # TODO: :target_page_id, :target_tab_id,
                  ].each do |attr|
                     assert( action.key?( attr ), "no #{ attr } at link action." )
                  end
               end
            end
         end
      end
   end
end
