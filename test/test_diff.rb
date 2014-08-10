#!/usr/bin/env ruby

require 'test/unit'
require 'ftools'

$:.unshift File.join( File.dirname( $0 ) )
$:.unshift File.join( File.dirname( $0 ), ".." )
require "graph.rb"
require "diff.rb"

class TestDiff < Test::Unit::TestCase
   BASEDIR = File.dirname( __FILE__ )
   include CMapUtils
   def test_statistics_merged_cmaps0
      pre_fname  = File.join( BASEDIR, "test-0-pre.dot")
      post_fname = File.join( BASEDIR, "test-0-post.dot")
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

      #pp stat[ :link_labels ]
      #pp stat[ :links ]
      assert_equal( 1, stat[ :link_labels ][ :common ].size )
      assert_equal( 14, stat[ :link_labels ][ :lost ].size )
      assert_equal( 17, stat[ :link_labels ][ :new ].size )
   end

   def test_statistics_merged_cmaps1
      pre_fname  = File.join( BASEDIR, "test-1-pre.dot")
      post_fname = File.join( BASEDIR, "test-1-post.dot")
      stat = statistics_merged_cmaps( open(pre_fname), open(post_fname) )
      #p stat
      assert( stat )
      assert( stat[ :nodes ] )
      assert( stat[ :links ] )

      assert_equal( 24, stat[ :pre ].node_count )
      assert_equal( 25, stat[ :pre ].edge_count )
      assert_equal( 10, stat[ :pre ].edge_labels.size )

      assert_equal( 24, stat[ :post ].node_count )
      assert_equal( 23, stat[ :post ].edge_count )
      assert_equal( 9, stat[ :post ].edge_labels.size )

      #p stat[ :nodes ][ :common ]
      assert_equal( 7, stat[ :nodes ][ :common ].size )
      assert_equal( 17, stat[ :nodes ][ :lost ].size )
      assert_equal( 17, stat[ :nodes ][ :new ].size )

      assert_equal( 4, stat[ :links ][ :common ].size )
      assert_equal( 21, stat[ :links ][ :lost ].size )
      assert_equal( 19, stat[ :links ][ :new ].size )

      assert_equal( 1, stat[ :link_labels ][ :common ].size )
      assert_equal( 9, stat[ :link_labels ][ :lost ].size )
      assert_equal( 8, stat[ :link_labels ][ :new ].size )
   end
end
