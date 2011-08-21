#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id: ext-graph-merge.rb,v 1.1 2010/04/25 06:29:29 masao Exp $

require "./graph.rb"

module CMapUtils
   DEFAULT_NODE_ATTR = " POINT-SIZE=\"9\" FACE=\"times\""
   def to_merged_dot( io_pre, io_post, style = {} )
      result = ""
      pre  = DirectedGraph.load_dot2( io_pre, true )
      post = DirectedGraph.load_dot2( io_post, true )

      node_attr = DEFAULT_NODE_ATTR
      node_attr = style[ :node_attr ] if style[ :node_attr ]

      result << "digraph G{\n"

      nodes = {}
      pre_cnodes = pre.canonical_node_labels
      post_cnodes = post.canonical_node_labels

      # ノードIDとラベルのハッシュ
      node_hash = {}
      pre_cnodes.each_with_index do |key, i|
         node_hash[ key ] ||= []
         node_hash[ key ] << "a#{i}"
      end
      post_cnodes.each_with_index do |key, i|
         node_hash[ key ] ||= []
         node_hash[ key ] << "b#{i}"
      end

      # Common nodes:
      ( pre_cnodes & post_cnodes ).each do |node|
         label = node
         if pre.canonical_label_mapping[ node ]
            label = pre.canonical_label_mapping[ node ]
         end
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ label }>, margin=\"0,0\", peripheries=2];\n"
      end
      # Lost nodes:
      ( pre_cnodes - post_cnodes ).each do |node|
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\", style=dotted];\n"
      end
      # New nodes:
      ( post_cnodes - pre_cnodes ).each do |node|
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\"];\n"
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
         result << link.map{|e| "\"#{ e }\"" }.join( "->" )
         label = ""
         label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre_e_labels[ link ]}</FONT><BR/>" if pre_e_labels[ link ]
         label << post_e_labels[ link ] if post_e_labels[ link ]
         result << " [ label=<#{ label }>, fontsize=12, arrowsize=2, color=\"#000000:#ffffff:#ffffff:#000000\" ];\n"
      end
      # Lost links:
      ( pre_e - post_e ).each do |link|
         result << link.map{|e| "\"#{ e }\"" }.join( "->" )
         label = ""
         label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre_e_labels[ link ] }</FONT><BR/>" if pre_e_labels[ link ]
         label << post_e_labels[ link ] if post_e_labels[ link ]
         result << " [ label=<#{ label }>, fontsize=12, style=dotted ];\n"
      end
      # New links:
      ( post_e - pre_e ).each do |link|
         result << link.map{|e| "\"#{ e }\"" }.join( "->" )
         label = ""
         label << post_e_labels[ link ] if post_e_labels[ link ]
         result << " [ label=\"#{ label }\", fontsize=12 ];\n"
      end

      result << "}"
      result
   end
end

if $0 == __FILE__
   if ARGV[0].nil? or ARGV[1].nil?
      puts "  Usage:  #{ $0 } pre.dot post.dot"
      exit
   end
   include CMapUtils
   puts to_merged_dot( open( ARGV[0] ), open( ARGV[1] ) )
end
