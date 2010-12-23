#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "converter.rb"

module QTHoney
   class TestLink < Test::Unit::TestCase
      LOG_TEST = File.join( File.dirname( __FILE__ ), "test-12.log" )

      def test_link
         open( LOG_TEST ) do |io|
            logdata = Log2.new( io ).convert
            assert( logdata )
            assert( logdata.size > 0 )
            assert( logdata.first )

            link_actions = logdata.select{|e| e[ :action ] == :link }
            assert_equal( 1, link_actions.size )
            link_actions.each do |action|
               [ :timestamp, :tab_id, :page_id, :url, :page_type, :title,
                 :anchor_text ].each do |attr|
                  assert( action.key?( attr ), "no #{ attr } at link action." )
               end
            end
         end
      end
   end
end
