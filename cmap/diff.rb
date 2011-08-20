#!/usr/bin/env ruby
# $Id: cmap-diff.rb,v 1.3 2010/12/19 08:40:43 masao Exp $

require "pp"
require "./graph.rb"

module CMapUtils
   def statistics_merged_cmaps( io_pre, io_post )
      result = {}
      pre  = DirectedGraph.load_dot2( io_pre, true )
      post = DirectedGraph.load_dot2( io_post, true )

      result[ :pre ] = pre
      result[ :post ] = post

      nodes = {}
      nodes[ :common ]  = pre.nodes & post.nodes
      nodes[ :lost ] = pre.nodes - post.nodes
      nodes[ :new ]   = post.nodes - pre.nodes
      result[ :nodes ] = nodes

      pre_e = pre.links_set
      post_e = post.links_set
      links = {}
      links[ :common ] = pre_e & post_e
      links[ :lost ] = pre_e - post_e
      links[ :new ]   = post_e - pre_e
      result[ :links ] = links

      link_labels = {}
      link_labels[ :common ] = links[ :common ].select{|e| pre.link_labels[ e ] and post.link_labels[ e ] and pre.link_labels[ e ] == post.link_labels[ e ] }
      link_labels[ :lost ] = links[ :lost ].select{|e| pre.link_labels[ e ] }
      link_labels[ :lost ] += links[ :common ].select{|e| pre.link_labels[ e ] and not post.link_labels[ e ] }
      link_labels[ :lost ] += links[ :common ].select{|e| pre.link_labels[ e ] and post.link_labels[ e ] and pre.link_labels[ e ] != post.link_labels[ e ]  }
      link_labels[ :new ] = links[ :new ].select{|e| post.link_labels[ e ] }
      link_labels[ :new ] += links[ :common ].select{|e| post.link_labels[ e ] and not pre.link_labels[ e ] }
      link_labels[ :new ] += links[ :common ].select{|e| post.link_labels[ e ] and pre.link_labels[ e ] and post.link_labels[ e ] != pre.link_labels[ e ]  }
      result[ :link_labels ] = link_labels

      result
   end

   def print_statistics( data, out = STDOUT )
      out.puts "Pre-nodes\t#{  data[ :pre  ].size }"
      out.puts "Post-nodes\t#{ data[ :post ].size }"
      [ :common, :lost, :new ].each do |c|
         # for Nodes:
         out.puts [ "#{ c } nodes".capitalize,
                    data[:nodes][c].size,
                    data[:nodes][c].to_a.sort.join(", ") ].join("\t")
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
