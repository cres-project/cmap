#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

require "stringio"

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "merge.rb"

class TestMerge < Test::Unit::TestCase
   BASEDIR = File.dirname( __FILE__ )
   include CMapUtils
   def test_to_merged_dot0
      pre_fname  = File.join( BASEDIR, "test-0-pre.dot")
      post_fname = File.join( BASEDIR, "test-0-post.dot")
      dot = to_merged_dot( open(pre_fname), open(post_fname) )
      #p dot
      assert( dot )
      assert_not_equal( dot, "" )
      dot_io = StringIO.new( dot )
      assert_nothing_raised do
         g = DirectedGraph.load_dot2( dot_io )
         #p g.nodes
      end
      dot_io.rewind
      dot_io
   end

   def test_to_merged_dot1
      pre_fname  = File.join( BASEDIR, "test-1-pre.dot")
      post_fname = File.join( BASEDIR, "test-1-post.dot")
      dot = to_merged_dot( open(pre_fname), open(post_fname) )
      #p dot
      assert( dot )
      assert_not_equal( dot, "" )
      dot_io = StringIO.new( dot )
      assert_nothing_raised do
         g = DirectedGraph.load_dot2( dot_io )
         # FIXME:
         assert_equal( 41, g.node_count )
         #p g.nodes
         #p g.edges[ "n4" ]
         #p g.edge_labels[ Set["n4","n5"] ]
         #p g.edge_labels
      end
      #dot_io.rewind
      #dot_io
   end
   def test_to_merged_dot3
      pre_fname  = File.join( BASEDIR, "test-3-pre.dot")
      post_fname = File.join( BASEDIR, "test-3-post.dot")
      dot = to_merged_dot( open(pre_fname), open(post_fname) )
      dot_io = StringIO.new( dot )
      g = DirectedGraph.load_dot2( dot_io )
      #puts g.to_dot
      assert( g.node_labels[ "n6" ] )
      assert_not_equal( "",  g.node_labels[ "n6" ] )
   end
   def test_to_merged_dot4
      pre_fname  = File.join( BASEDIR, "test-4-pre.dot")
      post_fname = File.join( BASEDIR, "test-4-post.dot")
      dot = to_merged_dot( open(pre_fname), open(post_fname) )
      dot_io = StringIO.new( dot )
      g = DirectedGraph.load_dot2( dot_io )
      #puts g.to_dot
      #p g.edges_from[ "root" ]
      assert( g.edges[ "root" ] )
      assert_nil( g.edges_from[ "root" ] )
   end
end
