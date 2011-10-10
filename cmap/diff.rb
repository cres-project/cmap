#!/usr/bin/env ruby
# $Id: cmap-diff.rb,v 1.3 2010/12/19 08:40:43 masao Exp $

require "pp"
$:.unshift File.dirname( $0 )
require "graph.rb"

module CMapUtils
   def statistics_merged_cmaps( io_pre, io_post )
      result = {}
      pre  = DirectedGraph.load_dot2( io_pre, true )
      post = DirectedGraph.load_dot2( io_post, true )

      result[ :pre ] = pre
      result[ :post ] = post

      nodes = {}

      pre_cnodes  = pre.canonical_node_labels
      post_cnodes = post.canonical_node_labels
      nodes[ :common ] =  pre_cnodes & post_cnodes
      #nodes[ :common ]  = pre.nodes & post.nodes
      nodes[ :lost ] = pre_cnodes - post_cnodes
      nodes[ :new ]   = post_cnodes - pre_cnodes
      result[ :nodes ] = nodes

      pre_e  = pre.canonical_links_set
      post_e = post.canonical_links_set
      links = {}
      links[ :common ] = pre_e & post_e
      links[ :lost ] = pre_e - post_e
      links[ :new ]   = post_e - pre_e
      result[ :links ] = links

      link_labels = {}
      link_labels[ :common ] = links[ :common ].select{|e| pre.canonical_link_labels[ e ] and post.canonical_link_labels[ e ] and pre.canonical_link_labels[ e ] == post.canonical_link_labels[ e ] }
      link_labels[ :lost ] = links[ :lost ].select{|e| pre.canonical_link_labels[ e ] }
      link_labels[ :lost ] += links[ :common ].select{|e| pre.canonical_link_labels[ e ] and not post.canonical_link_labels[ e ] }
      link_labels[ :lost ] += links[ :common ].select{|e| pre.canonical_link_labels[ e ] and post.canonical_link_labels[ e ] and pre.canonical_link_labels[ e ] != post.canonical_link_labels[ e ]  }
      link_labels[ :new ] = links[ :new ].select{|e| post.canonical_link_labels[ e ] }
      link_labels[ :new ] += links[ :common ].select{|e| post.canonical_link_labels[ e ] and not pre.canonical_link_labels[ e ] }
      link_labels[ :new ] += links[ :common ].select{|e| post.canonical_link_labels[ e ] and pre.canonical_link_labels[ e ] and post.canonical_link_labels[ e ] != pre.canonical_link_labels[ e ]  }
      result[ :link_labels ] = link_labels

      result
   end

   def print_statistics( data, out = STDOUT )
      out.puts "Pre-nodes\t#{  data[ :pre  ].size }"
      out.puts "Post-nodes\t#{ data[ :post ].size }"
      label_target = {
         :common => :pre,
         :lost   => :pre,
         :new    => :post,
      }
      [ :common, :lost, :new ].each do |c|
         # for Nodes:
         #p label_target[ c ]
         #p data[label_target[c]].node_labels["id0"]
         out.puts [
             "#{ c } nodes".capitalize,
             data[:nodes][c].size,
             data[:nodes][c].to_a.sort.map{|e|
                      if data[label_target[c]].canonical_label_mapping[e]
                         "{#{e}}:#{ data[label_target[c]].canonical_label_mapping[e] }"
                      else
                         e
                      end
                   }.join(", ")
         ].join("\t")
      end

      out.puts "Pre-links\t#{  data[ :pre  ].link_count }"
      out.puts "Post-links\t#{ data[ :post ].link_count }"
      [ :common, :lost, :new ].each do |c|
         # for Links:
         out.puts [ "#{ c } links".capitalize,
                data[:links][c].size,
                data[:links][c].to_a.map{|e| "{#{e.to_a.sort.join(",")}}" }.sort.join(", ") ].join("\t")
      end

      out.puts "Pre-link-labels\t#{  data[ :pre  ].link_labels.size }"
      out.puts "Post-link-labels\t#{ data[ :post ].link_labels.size }"
      [ :common, :lost, :new ].each do |c|
         target = case c
                  when :common, :new
                     target = :post
                  when :lost
                     target = :pre
                  end
         # for Link labels:
         out.puts [ "#{ c } link labels".capitalize,
                data[ :link_labels ][c].size,
                data[ :link_labels ][c].map{|e|
                   "#{ data[ target ].link_labels[e] }:#{ e.to_a.join(",") }"
                }.sort.join(", ")
              ].join("\t")
      end
   end
end

if $0 == __FILE__
   if ARGV[0].nil? or ARGV[1].nil?
      puts "  Usage:  #{ $0 } pre.dot post.dot"
      exit
   end
   include CMapUtils
   data = statistics_merged_cmaps( open( ARGV[0] ), open( ARGV[1] ) )
   print_statistics( data )
end
