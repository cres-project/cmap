#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "graph.rb"
require "diff.rb"

class TestDiff < Test::Unit::TestCase
   include CMapUtils
   def test_statistics_merged_cmaps
      pre_fname  = File.join( File.dirname( $0 ), "test", "test-0-pre.dot")
      post_fname = File.join( File.dirname( $0 ), "test", "test-0-post.dot")
      stat = statistics_merged_cmaps( open(pre_fname), open(post_fname) )
      #p stat
      assert( stat )
      assert( stat[ :nodes ] )
      assert( stat[ :links ] )

      assert_equal( 16, stat[ :pre ].node_count )
      assert_equal( 15, stat[ :pre ].edge_count )
      assert_equal( 15, stat[ :pre ].edge_labels.size )

      assert_equal( 18, stat[ :post ].node_count )
      assert_equal( 18, stat[ :post ].edge_count )
      assert_equal( 18, stat[ :post ].edge_labels.size )

      assert_equal( 6, stat[ :nodes ][ :common ].size )
      assert_equal( 10, stat[ :nodes ][ :lost ].size )
      assert_equal( 12, stat[ :nodes ][ :new ].size )

      assert_equal( 3, stat[ :links ][ :common ].size )
      assert_equal( 12, stat[ :links ][ :lost ].size )
      assert_equal( 15, stat[ :links ][ :new ].size )

      assert_equal( 1, stat[ :link_labels ][ :common ].size )
      assert_equal( 14, stat[ :link_labels ][ :lost ].size )
      assert_equal( 17, stat[ :link_labels ][ :new ].size )
   end
end
