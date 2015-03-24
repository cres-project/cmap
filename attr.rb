#!/usr/bin/env ruby
# $Id: ext-graph-attr.rb,v 1.4 2010/01/13 20:57:17 masao Exp $

require "open3"
require "pp"

$:.push( File.dirname( __FILE__ ) )
require "graph"

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
   count = {}
   g.nodes.each do |n|
      children = g.edges_to[n]
      children_size = 0
      children_size = children.size if children
      count[ children_size ] ||= []
      count[ children_size ] << n
   end
   ( 0..count.keys.max ).each do |i|
      if count[i]
         puts [ "children_size #{i}", count[i].size, count[i].join(", ") ].join( "\t" )
      else 
         puts "children_size #{i}\t0" if not count[i]
      end
   end
end
