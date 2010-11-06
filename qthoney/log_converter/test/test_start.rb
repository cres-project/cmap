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
            logdata = Log2.new( io )
         end
      end
   end
end
