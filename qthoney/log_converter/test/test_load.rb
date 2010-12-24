#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestLoad < Test::Unit::TestCase
      def test_load
         {  "test-12.log" => 1,
            "test-14.log" => 1,
         }.each do |file, linkcount|
            open( File.join( File.dirname( __FILE__ ), file ) ) do |io|
               logdata = Log2.new( io ).convert
               assert( logdata )
               assert( logdata.size > 0 )
               assert( logdata.first )
               load_actions = logdata.select{|e| e[ :action ] == :load }
               assert_equal( 2, load_actions.size )
               load_actions.each do |action|
                  assert( action.key?( :timestamp ) )
                  assert( action.key?( :tab_id ) )
                  assert( action.key?( :page_id ) )
                  assert( action.key?( :url ) )
                  assert( action.key?( :page_type ) )
                  assert( action.key?( :title ) )
               end
            end
         end
      end
   end
end
