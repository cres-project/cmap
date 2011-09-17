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
   def test_canonical_node_labels
      pre1_fname = File.join( File.dirname( $0 ), "test", "test-1-pre.dot")
      g = Graph.load_dot2( open(pre1_fname) )
      nlabels = g.canonical_node_labels
      assert( nlabels )
      assert( nlabels.member?( "environmental issues" ) )
      assert( nlabels.member?( "n2" ) )
      #assert( nlabels.member?( "climate change" ) )
      assert( g.canonical_label_mapping )
      assert_equal( g.canonical_label_mapping[ "n2" ], "climate change" )
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
   def test_load_dot2_root
      pre0_fname = File.join( File.dirname( $0 ), "test", "test-0-pre.dot")
      g = DirectedGraph.load_dot2( open(pre0_fname), true, true )
      assert( g )
      nlabels = g.canonical_node_labels
      assert( nlabels.member?( "root" ) )
   end
   def test_canonical_node_labels
      pre1_fname = File.join( File.dirname( $0 ), "test", "test-1-pre.dot")
      g = DirectedGraph.load_dot2( open(pre1_fname) )
      nlabels = g.canonical_node_labels
      assert( nlabels )
      assert( nlabels.member?( "environmental issues" ) )
      assert( nlabels.member?( "n2" ) )
      #assert( nlabels.member?( "climate change" ) )
      assert( g.canonical_label_mapping )
      assert_equal( g.canonical_label_mapping[ "n2" ], "climate change" )

      # for multiple identical nodes on a single cmap.
      pre3_fname = File.join( File.dirname( $0 ), "test", "test-3-pre.dot")
      post3_fname = File.join( File.dirname( $0 ), "test", "test-3-pre.dot")
      g = DirectedGraph.load_dot2( open(pre3_fname) )
      g2 = DirectedGraph.load_dot2( open(post3_fname) )
      nlabels = g.canonical_node_labels
      assert( nlabels )
      assert( nlabels.member?( "n6" ) )
      assert_equal( 33, nlabels.size )
      nlabels2 = g2.canonical_node_labels
      assert( nlabels.member?( "n6" ) )

      elabels = g.canonical_edge_labels
      elabels2 = g2.canonical_edge_labels
   end
   def test_link_lables_size
      fname = File.join( File.dirname($0), "test", "test-2-pre.dot" )
      g = DirectedGraph.load_dot2( open(fname) )
      assert( g )
      assert_equal( 13, g.link_labels.size )
   end
   def test_direction_of_links
      fname = File.join( File.dirname($0), "test", "test-3-pre.dot" )
      g = DirectedGraph.load_dot2( open(fname) )
      assert( g.edges_from["id2"].include?( "id1" ) )
      dot = g.to_dot
      #p dot
      assert( dot )
      dot_io = StringIO.new( dot )
      g2 = DirectedGraph.load_dot2( dot_io )
      #p g2
      assert_equal( g2.nodes, g.nodes )
      assert( g2.edges_from[ "id2" ] )
      assert( g2.edges_from[ "id2" ].include?( "id1" ) )
   end
end
