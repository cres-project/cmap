#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestEnd < Test::Unit::TestCase
      LOG_TEST1 = File.join( File.dirname( __FILE__ ), "test-2.log" )
      def test_end1
         open( LOG_TEST1 ) do |io|
            logdata = Log2.new( io ).convert
            assert( logdata )
            assert( logdata.size > 0 )

            log_action_end = logdata.select{|log| log[ :action ] == :end }
            assert( log_action_end.size > 0, "There is no action 'end'."  )
            assert_equal( 2, log_action_end.size,  "There must be two 'end' actions."  )
            log_action_end.each do |log|
               assert( log.key?( :timestamp ) )
               assert( log.key?( :tab_id ) )
               assert( log.key?( :page_id ),
                       "There is no 'page_id' for action 'end'." )
               assert( log.key?( :page_type ) )
               assert_equal( :non_serp, log[ :page_type ] )
            end
            assert_equal( 1289031442757, log_action_end[ 0 ][ :timestamp ] )
            assert_equal( 1289031451330, log_action_end[ 1 ][ :timestamp ] )
         end
      end
   end
end
