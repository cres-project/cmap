#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestPageType < Test::Unit::TestCase
      LOG_TEST1 = File.join( File.dirname( __FILE__ ), "test-001.log" )

      def test_pagetype
         open( LOG_TEST1 ) do |io|
            logdata = Log2.new( io )
            pagetype = logdata.url_page_type( "http://google.co.jp/search?q=test" )
            assert( pagetype )
            assert( :serp, pagetype[ :type ] )
         end
      end
   end
end


