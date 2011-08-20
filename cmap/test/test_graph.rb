#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "graph.rb"

class TestGraph < Test::Unit::TestCase
   def test_load_dot2
      pre0_fname = File.join( File.dirname( $0 ), "test", "test-0-pre.dot")
      g = Graph.load_dot2( open(pre0_fname) )
      #p g.nodes
      assert( g )
      assert_equal( 16, g.node_count )
      assert_equal( 15, g.edge_count )
   end
end

class TestDirectedGraph < Test::Unit::TestCase
   def test_load_dot2
      pre0_fname = File.join( File.dirname( $0 ), "test", "test-0-pre.dot")
      g = DirectedGraph.load_dot2( open(pre0_fname) )
      #p g.nodes
      assert( g )
      assert_equal( 16, g.node_count )
      assert_equal( 15, g.edge_count )
   end
end
