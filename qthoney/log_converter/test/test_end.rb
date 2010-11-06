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
            log_action_end.each do |log|
               assert( log.key?( :timestamp ) )
               assert( log.key?( :tab_id ) )
               assert( log.key?( :page_id ),
                       "There is no 'page_id' for action 'end'." )
            end
         end
      end
   end
end
