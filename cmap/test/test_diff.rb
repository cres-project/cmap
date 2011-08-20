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
   end
end
