#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

require "stringio"

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "merge.rb"

class TestMerge < Test::Unit::TestCase
   include CMapUtils
   def test_to_merged_dot0
      pre_fname  = File.join( File.dirname( $0 ), "test", "test-0-pre.dot")
      post_fname = File.join( File.dirname( $0 ), "test", "test-0-post.dot")
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
      pre_fname  = File.join( File.dirname( $0 ), "test", "test-1-pre.dot")
      post_fname = File.join( File.dirname( $0 ), "test", "test-1-post.dot")
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
end
