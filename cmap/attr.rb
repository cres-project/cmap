#!/usr/bin/env ruby
# $Id: ext-graph-attr.rb,v 1.4 2010/01/13 20:57:17 masao Exp $

require "graph"
require "open3"
require "pp"

ARGV.each do |f|
   STDERR.puts f
   g = nil
   open( f ) do |io|
      g = DirectedGraph.load_dot2( io )
   end
   puts "Nodes: #{ g.node_count }"
   puts "Edges: #{ g.edge_count }"
   puts "Edge labels: #{ g.edge_labels.size }"
   #p g.edge_labels
   #puts "Clustering coefficience: #{ g.clustering_coefficient }"
   #puts "Average shortest path: #{ g.mean_average_shortest_path }"
   root = "id0"
   dists = g.warshal_floyd_shortest_paths
   count = {}
   g.nodes.each do |n|
      next if n == root
      count[ dists[ Set[root,n] ] ] ||= []
      count[ dists[ Set[root,n] ] ] << n
   end
   puts "Distance from the root node (#{ root }):"
   count.keys.sort.each do |i|
      puts [ "dist#{i}", count[i].size, count[i].join(", ") ].join( "\t" )
   end
end
