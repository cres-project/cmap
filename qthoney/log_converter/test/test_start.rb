#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestStart < Test::Unit::TestCase
      LOG_TEST1 = File.join( File.dirname( __FILE__ ), "test-1.log" )

      def test_start1
         open( LOG_TEST1 ) do |io|
            logdata = Log2.new( io ).convert
            assert( logdata )
            assert( logdata.size > 0 )
            assert( logdata.first )

            action_start = logdata.first
            assert( action_start[ :action ] )
            assert_equal( :start, action_start[ :action ] )
            assert( action_start.key?( :timestamp ) )
            assert( action_start.key?( :tab_id ) )
         end
      end
   end
end
