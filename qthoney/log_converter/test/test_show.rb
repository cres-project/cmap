#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestShow < Test::Unit::TestCase
      LOG_TEST = File.join( File.dirname( __FILE__ ), "test-012.log" )

      def test_show
         open( LOG_TEST ) do |io|
            logdata = Log2.new( io ).convert
            assert( logdata )
            assert( logdata.size > 0 )
            assert( logdata.first )

            show_actions = logdata.select{|e| e[ :action ] == :show }
            assert_equal( 2, show_actions.size )
            show_actions.each do |action|
               assert( action.key?( :timestamp ), :timestamp )
               assert( action.key?( :tab_id ), "no tab_id at show action." )
               assert( action.key?( :page_id ), "no page_id at show action." )
               assert( action.key?( :url ), "no url at show action." )
               assert( action.key?( :page_type ), "no page_type at show action." )
               assert( action.key?( :title ), "no title at show action." )
            end
         end
      end
   end
end
