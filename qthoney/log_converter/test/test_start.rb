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
            assert( logdata.first[ :action ] )
            assert_equal( :start, logdata.first[ :action ] )
         end
      end
   end
end
