#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "stringio"

$:.unshift File.join( File.dirname( __FILE__ ) )
require "graph.rb"

module CMapUtils
   DEFAULT_NODE_ATTR = " POINT-SIZE=\"9\" FACE=\"times\""
   def to_simple_merged_dot( files, style = {} )
      total = DirectedGraph.new
      result = "digraph G{\n"
      files.each do |file|
	 graph_io = open( file )
         # check if contents includes BOM snippets.
         cont = graph_io.read
         if cont[ 0, 3 ] == "\xEF\xBB\xBF"
            STDERR.puts "BOM detected."
            graph_io = StringIO.new( cont[ 3..-1 ] )
         else
            graph_io.rewind
         end
	 graph = DirectedGraph.load_dot2( graph_io, true, true )
         #p graph.nodes
         graph.each_node do |node|
            #p graph
            #p node
            #p [node, graph.node_labels[ node ] ]
            #puts graph.canonical_node_label( node, true )
            label = get_label( graph.node_labels[ node ] )
            #puts label
            total.add_node( label )
            if graph.edges_to[ node ]
               graph.edges_to[ node ].each do |node2|
                  label2 = get_label( graph.node_labels[ node2 ] )
                  total.add_node( label2 )
                  total.add_edge( label, label2 )
               end
            end
         end
      end
      #p total.nodes
      total.to_dot
   end

   private
   def get_label( n )
      label = n
      label = $1 if label =~ /\A\w+:(.+)\Z/
      label
   end
end

if $0 == __FILE__
   if ARGV.empty?
      puts "  Usage:  #{ $0 } foo.dot ..."
      exit
   end
   include CMapUtils
   puts to_simple_merged_dot( ARGV )
end
