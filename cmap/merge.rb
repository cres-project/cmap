#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id: ext-graph-merge.rb,v 1.1 2010/04/25 06:29:29 masao Exp $

require "graph"
require "open3"

# Usage: ./ext-graph-diff.rb <___pre.dot> <___post.dot>
# ex. ./ext-graph-diff.rb tsub032_politics_2_pre.dot tsub032_politics_2_post.dot | nkf

pre  = DirectedGraph.load_dot2( open( ARGV[0] ), true )
post = DirectedGraph.load_dot2( open( ARGV[1] ), true )

# ノードIDとラベルのハッシュ
node_hash = {}
pre.each_with_index do |node, i|
   key = pre.node_labels[ node ]
   node_hash[ key ] ||= []
   node_hash[ key ] << "a#{i}"
end
post.each_with_index do |node, i|
   key = post.node_labels[ node ]
   node_hash[ key ] ||= []
   node_hash[ key ] << "b#{i}"
end

puts "digraph G{"

nodes = {}
pre_nodes = Set[ *pre.node_labels.values ]
post_nodes = Set[ *post.node_labels.values ]
NODEID_ATTR = " POINT-SIZE=\"9\" FACE=\"times\""
# Common nodes:
( pre_nodes & post_nodes ).each do |node|
   puts "\"#{ node }\" [ label=<<FONT#{ NODEID_ATTR }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\", peripheries=2];"
end
# Lost nodes:
( pre_nodes - post_nodes ).each do |node|
   puts "\"#{ node }\" [ label=<<FONT#{ NODEID_ATTR }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\", style=dotted];"
end
# New nodes:
( post_nodes - pre_nodes ).each do |node|
   puts "\"#{ node }\" [ label=<<FONT#{ NODEID_ATTR }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\"];"
end

pre_e = Set[]
pre_e_labels = {}
pre.each_node do |node1|
   n1 = pre.node_labels[ node1 ]
   if pre.edges_to[ node1 ]
      pre.edges_to[ node1 ].each do |node2|
         n2 = pre.node_labels[ node2 ]
         pre_e << [ n1, n2 ]
         pre_e_labels[ [n1, n2] ] = pre.edge_labels[ Set[node1,node2] ]
      end
   end
end
post_e = Set[]
post_e_labels = {}
post.each_node do |node1|
   n1 = post.node_labels[ node1 ]
   if post.edges_to[ node1 ]
      post.edges_to[ node1 ].each do |node2|
         n2 = post.node_labels[ node2 ]
         post_e << [ n1, n2 ]
         post_e_labels[ [n1, n2] ] = post.edge_labels[ Set[node1,node2] ]
      end
   end
end
# $KCODE = "u"
# p post.edge_labels

# Common links:
( pre_e & post_e ).each do |link|
   print link.map{|e| "\"#{ e }\"" }.join( "->" )
   label = ""
   label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre_e_labels[ link ]}</FONT><BR/>" if pre_e_labels[ link ]
   label << post_e_labels[ link ] if post_e_labels[ link ]
   puts " [ label=<#{ label }>, fontsize=12, arrowsize=2, color=\"#000000:#ffffff:#ffffff:#000000\" ];"
end
# Lost links:
( pre_e - post_e ).each do |link|
   print link.map{|e| "\"#{ e }\"" }.join( "->" )
   label = ""
   label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre_e_labels[ link ] }</FONT><BR/>" if pre_e_labels[ link ]
   label << post_e_labels[ link ] if post_e_labels[ link ]
   puts " [ label=<#{ label }>, fontsize=12, style=dotted ];"
end
# New links:
( post_e - pre_e ).each do |link|
   print link.map{|e| "\"#{ e }\"" }.join( "->" )
   label = ""
   label << post_e_labels[ link ] if post_e_labels[ link ]
   puts " [ label=\"#{ label }\", fontsize=12 ];"
end

puts "}"
