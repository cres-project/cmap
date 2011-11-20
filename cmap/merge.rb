#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$:.unshift File.join( File.dirname( __FILE__ ) )
require "graph.rb"

module CMapUtils
   DEFAULT_NODE_ATTR = " POINT-SIZE=\"9\" FACE=\"times\""
   def to_merged_dot( io_pre, io_post, style = {} )
      result = ""
      pre  = DirectedGraph.load_dot2( io_pre, true, true )
      post = DirectedGraph.load_dot2( io_post, true, true )
      #puts pre.root_node

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
         user_attr = ""
         if pre.canonical_label_mapping[ node ] and post.canonical_label_mapping[ node ]
            if node == "root"
               user_attr = ", shape=box, color=\"blue\""
            else
               user_attr = ", penwidth=3, color=\"red\""
            end
         end
         if pre.canonical_label_mapping[ node ] and post.canonical_label_mapping[ node ] and pre.canonical_label_mapping[ node ] == post.canonical_label_mapping[ node ]
            label = pre.canonical_label_mapping[ node ]
         else
            if pre.canonical_label_mapping[ node ] or post.canonical_label_mapping[ node ]
               label = "<FONT COLOR=\"gray\">#{ pre.canonical_label_mapping[ node ]}</FONT><BR/>"
               label << " " + post.canonical_label_mapping[ node ]
            else
               label = node
            end
         end
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ label }>, margin=\"0,0\", peripheries=2#{ user_attr }];\n"
      end
      # Lost nodes:
      ( pre_cnodes - post_cnodes ).each do |node|
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\", style=dotted];\n"
      end
      # New nodes:
      ( post_cnodes - pre_cnodes ).each do |node|
         result << "\"#{ node }\" [ label=<<FONT#{ node_attr }>#{ node_hash[node].join(",") }</FONT> #{ node }>, margin=\"0,0\"];\n"
      end

      pre_e  = pre.canonical_links_set
      post_e = post.canonical_links_set
      # $KCODE = "u"
      # p post.edge_labels

      # Common links:
      ( pre_e & post_e ).each do |link|
         result << link_to_dot( link, pre )
         label = ""
         if post.canonical_link_labels[ link ] and pre.canonical_link_labels[ link ] and pre.canonical_link_labels[ link ] ==  post.canonical_link_labels[ link ]
            label << "<U>#{ pre.canonical_link_labels[ link ]}</U>"
         else
            label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre.canonical_link_labels[ link ]}</FONT><BR/>" if pre.canonical_link_labels[ link ]
            label << " " + post.canonical_link_labels[ link ] if post.canonical_link_labels[ link ]
         end
         result << " [ label=<#{ label }>, fontsize=12, arrowsize=2, color=\"#000000:#ffffff:#ffffff:#000000\" ];\n"
      end
      # Lost links:
      ( pre_e - post_e ).each do |link|
         result << link_to_dot( link, pre )
         label = ""
         label << "<FONT COLOR=\"gray\" POINT-SIZE=\"12\">#{ pre.canonical_link_labels[ link ] }</FONT>" if pre.canonical_link_labels[ link ]
         result << " [ label=<#{ label }>, fontsize=12, style=dotted ];\n"
      end
      # New links:
      ( post_e - pre_e ).each do |link|
         result << link_to_dot( link, post )
         label = ""
         label << post.canonical_link_labels[ link ] if post.canonical_link_labels[ link ]
         result << " [ label=\"#{ label }\", fontsize=12 ];\n"
      end

      result << "}"
      result
   end

   # Formatting a link in Dot format.
   def link_to_dot( link_set, g = nil )
      case link_set.size
      when 2
         if g
            n1, n2, = link_set.to_a
            n1_original = n1
            n2_original = n2
            inv_label_mapping = g.canonical_label_mapping.invert
            g.canonical_label_mapping.each do |k, v|
               case k
               when n1
                  alt_label = "#{n1}:#{v}"
                  n1_original = g.node_labels.invert[ alt_label ]
               when n2
                  alt_label = "#{n2}:#{v}"
                  n2_original = g.node_labels.invert[ alt_label ]
               end
            end
            n1_original = g.node_labels.invert[ n1 ] if n1 == n1_original
            n2_original = g.node_labels.invert[ n2 ] if n2 == n2_original
            n1_original = g.root_node if n1 == "root"
            n2_original = g.root_node if n2 == "root"
            #if n1 == "n5" or n2 == "n5"
               #p inv_label_mapping
               #p g.edges_to
               #p [ n1, n1_original, g.edges_to[n1], g.edges_to[n1_original] ]
               #p [ n2, n2_original, g.edges_to[n2], g.edges_to[n2_original] ]
            #end
            if g.edges_to[ n1_original ] and g.edges_to[ n1_original ].include?( n2_original )
               "\"#{ n1 }\" -> \"#{ n2 }\""
            else
               "\"#{ n2 }\" -> \"#{ n1 }\""
            end
         else
            link_set.map{|e| "\"#{ e }\"" }.join( "->" )
         end
      when 1
         member = link_set.to_a[0]
         "\"#{ member }\"->\"#{ member }\""
      else
         nil
      end
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
