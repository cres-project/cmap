#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

require "stringio"

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "ext-graph-pairs.rb"

class TestExtGraphPairs < Test::Unit::TestCase
   BASEDIR = File.dirname( __FILE__ )
   def test_to_node_pairs
      post_fname = File.join( BASEDIR, "test-0-post.dot")
      g = DirectedGraph.load_dot2( open(post_fname) )
      results = g.to_node_pairs
      strio = StringIO.new( results )
      header = strio.gets # skip header
      header_a = header.chomp.split( /\t/ )
      assert_equal( header_a[0], "Cmap" )

      data0 = strio.gets.chomp.split( /\t/ )
      assert_equal( data0, ["", "Democratic Party", "Hatoyama", "conduct" ] )
      #test-0-post     Democratic Party        Hatoyama        conduct
      #test-0-post     Democratic Party        Effect of a change of government        make
   end
end
