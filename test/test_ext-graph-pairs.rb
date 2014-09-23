#!/usr/bin/env ruby

require 'test/unit'

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
      header = strio.gets
      header_a = header.chomp.split( /\t/ )
      assert_equal( header_a[0], "Cmap" )

      data0 = strio.gets.chomp.split( /\t/ )
      assert_equal( data0, ["", "1", "0", "Democratic Party", "Effect of a change of government", "make" ] )
      data1 = strio.gets.chomp.split( /\t/ )
      assert_equal( data1, ["", "1", "2", "Democratic Party", "Hatoyama", "conduct" ] )
      data2 = strio.gets.chomp.split( /\t/ )
      assert_equal( data2, ["", "2", "3", "Hatoyama", "Mrs. Miyuki Hatoyama", "with" ] )

      pre_fname = File.join( BASEDIR, "test-0-pre.dot")
      g = DirectedGraph.load_dot2( open(pre_fname) )
      results = g.to_node_pairs
      strio = StringIO.new( results )
      strio.gets # skip header
      data0 = strio.gets.chomp.split( /\t/ )
      assert_equal( data0, [ "", "4", "5", "Akihabara", "electric city", "is" ] )

   end
end
