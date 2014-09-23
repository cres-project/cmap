#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$:.unshift File.dirname(__FILE__)
require "graph.rb"

class DirectedGraph
  def to_node_pairs( name )
    str = %W[ Cmap node1 node2 link_label category category_node1 category_node2 ].join( "\t" )
    str << "\n"
    self.each do |n1|
      next if edges_to[n1].nil?
      edges_to[n1].each do |n2|
        edge_label = edge_labels[ Set[n1,n2] ]
        str << [ name, node_labels[n1], node_labels[n2], edge_label, ].join( "\t" )
	str << "\n"
      end
    end
    str
  end
end

ARGV.each do |f|
  g = DirectedGraph.load_dot2( open(f) )
  basename = File.basename( f, ".dot" )
  puts g.to_node_pairs( basename )
end
