#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "open3"
require "set"
require "shellwords"
require "nkf"
require "stringio"

class String
   def normalize_ja
      NKF.nkf( "-wWXZ1", self ).gsub( /\s+/, " " ).strip
   end
end

class Graph
   attr_reader :nodes
   attr_reader :node_labels
   attr_reader :edges
   attr_reader :edge_labels
   attr_accessor :root_node
   alias :link_labels :edge_labels
   def initialize
      @nodes = Set[]
      @edges = {}
      @node_labels = {}
      @edge_labels = {}
      #STDERR.puts @nodes.inspect
   end
   def add_node( n, label = n )
      @nodes << n
      @node_labels[ n ] = label
      @edges[n] ||= Set.new
   end
   def add_edge( n1, n2, label = nil )
      @nodes << n1
      @nodes << n2
      @edges[n1] ||= Set.new
      @edges[n1] << n2
      @edges[n2] ||= Set.new
      @edges[n2] << n1
      @edge_labels[ Set[n1, n2] ] = label if label
   end
   def each_node
      @nodes.sort.each do |node|
         yield node
      end
   end
   alias :each :each_node
   include Enumerable

   def canonical_node_label( n, unified = true )
      @canonical_label_mapping ||= {}
      label = n
      if @node_labels[ n ]
         label = @node_labels[ n ]
         if unified and label =~ /\A(\w+):(.*)\Z/
            label = $1
            if @canonical_label_mapping[ $1 ] and @canonical_label_mapping[ $1 ] != $2
               @canonical_label_mapping[ $1 ] << "\t"+ $2
            else
               @canonical_label_mapping[ $1 ] = $2
            end
         end
      end
      label
   end
   def canonical_node_labels( unified = true )
      labels = Set.new
      @nodes.each do |e|
         labels << canonical_node_label( e, unified )
      end
      labels
   end
   attr_reader :canonical_label_mapping

   def canonical_edge_labels( unified = true )
      labels = {}
      @edge_labels.each do |set, label|
         set_new = Set.new( set.to_a.map{|e| canonical_node_label( e, unified ) } )
         labels[ set_new ] = label
      end
      labels
   end
   alias :canonical_link_labels :canonical_edge_labels

   def neighbors( node )
      @edges[node] - Set[ node ]
   end
   def neighbors_all( node )
      STDERR.puts "neighbor_all #{node.inspect} #{neighbors(node).inspect}" if $DEBUG
      @done = {}
      @done[node] = true
      set = Set.new

      #Loop version:
      new = neighbors(node)
      while not new.empty? do
         n = new.to_a.shift
         #STDERR.puts "new:"+new.inspect
         #STDERR.puts "n:"+n.inspect
         new.delete( n )
         next if @done[n]
         @done[n] = true
         new.merge( neighbors(n) )#- @done.keys )
         set << n
         STDERR.puts "#{new.size}\tdone:#{@done.size}\tset:#{set.size}" if $DEBUG
         #STDERR.puts new.inspect
      end

      #Recursive version:
      #neighbors(node).each do |n|
      #   next if @done[n]
      #   set.merge _neighbors_all(n)
      #   @done[n] = true
      #end
      set - Set[ node ]
   end
   def _neighbors_all( node )
      return [] if @done[node]
      STDERR.puts "_neighbors_all #{node.inspect} #{@done.inspect}" if $DEBUG
      set = Set[ node ]
      @done[node] = true
      neighbors(node).each do |n|
         next if @done[n]
         set.merge _neighbors_all(n)
         @done[n] = true
      end
      set
   end

   def size
      @nodes.size
   end
   alias :node_count :size

   def edges_set
      set = Set[]
      each_node do |node|
         @edges[ node ].each do |n1|
            set << Set[node,n1]
         end
      end
      set
   end
   def canonical_edges_set( unified = true )
      set = Set[]
      each_node do |node|
         @edges[ node ].each do |n1|
            set << Set[
                   canonical_node_label( node, unified ),
                   canonical_node_label( n1, unified )
               ]
         end
      end
      set
   end
   alias :links_set :edges_set
   alias :canonical_links_set :canonical_edges_set

   def edge_count
      edges_set.size
   end
   alias :link_count :edge_count

   def delete( set )
      @nodes -= set
      set.each do |node|
         @edges.delete(node)
      end
   end

   def to_dot( attr = {} )
      done = {}
      str = "graph {\n"
      self.each_node do |n|
         if attr[n]
            attr_s = attr[n].keys.sort.map{|e| %Q|#{e}="#{attr[n][e]}"| }.join(",")
            str << "#{ n } [ #{attr_s} ]\n"
         end
         self.neighbors( n ).each do |neighbor|
            pair = Set[ n, neighbor ]
            if not done[ pair ]
               if attr[ pair ]
                  attr_s = attr[ pair ].keys.sort.map{|e| %Q|#{e}="#{attr[pair][e]}"| }.join(",")
                  str << "#{ n } -- #{ neighbor } [ #{attr_s} ]\n"
               else
                  str << "#{ n } -- #{ neighbor }\n"
               end
               done[ pair ] = true
            end
         end
      end
      str << "}"
      str
   end

   def self.load_dot( io )
      g = Graph.new
      io.each do |line|
         case line
         when /^\s*(\w+)\s*(\[.*?\])?;?\s*$/
            g.add_node( $1 )
         when /^\s*(\w+)\s*--\s*(\w+)\s*(\[.*?\])?;?\s*$/
            g.add_edge( $1, $2 )
         end
      end
      g
   end
   # Graph#load_dot2 requires "dot" command.
   def self.load_dot2( io, normalize = false, root = false )
      # STDERR.puts f
      root_node = false
      pin, pout, perr = *Open3.popen3( "dot", "-Tplain" )
      cont = io.read
      if cont[ 0, 3 ] == "\xEF\xBB\xBF"
         STDERR.puts "BOM detected."
         cont = cont[ 3..-1 ]
      end
      pin.print cont
      pin.close
      g = Graph.new
      pout.each do |line|
         # p line
         case line
         when /\Anode /
            node = Shellwords.shellwords( line.chomp )[1]
            node = node.normalize_ja if normalize
            label = Shellwords.shellwords( line.chomp )[6]
            label = label.normalize_ja if normalize
            if root and not root_node
               label = "root:" + label
               root_node = node
               g.root_node = root_node
               #p "root_node:" + root_node
            end
            g.add_node( node, label )
         when /\Aedge /
            data = Shellwords.shellwords( line.chomp )
            num = data[3].to_i
            # cf. http://graphviz.org/content/output-formats#dplain
            ## ( 6 == "edge", head, tail, n, style, and color )
            label = if data.size > ( 6 + 2*num )
                       data[-5]
                    else
                       nil
                    end
            if normalize
               data[1] = data[1].normalize_ja
               data[2] = data[2].normalize_ja
            end
            g.add_edge( data[1], data[2], label )
         else
            #p line
         end
      end
      pout.close
      perr.close
      g
   end

   def get_components
      comps = []
      g = Marshal.load( Marshal.dump(self) ) # deep copy
      while g.size > 0 do
         start = g.nodes.to_a.shift
         set = Set[ start ]
         #STDERR.puts start
         set << g.neighbors_all(start)
         set.flatten!
         g.delete(set)
         comps << set
      end
      comps
   end

   def clustering_coefficient
      sum = 0
      nodes.each do |e|
         neighbor_nodes = neighbors( e )
         neighbor_size = neighbor_nodes.size
         next if neighbor_nodes.empty?
         set = Set[]
         neighbor_nodes.each do |n|
            ( edges[n] & neighbor_nodes ).each do |n2|
               set << Set[ n, n2 ]
            end
         end
         #p [e, set]
         ci = ( 2 * set.size ) / ( neighbor_size * (neighbor_size-1) ).to_f
         sum += ci
      end
      sum / size
   end
   def average_shortest_path
      dists = warshal_floyd_shortest_paths
      average_length = {}
      nodes.each do |n|
         sum = 0
         node_paths = dists.keys.select do |e|
            e.include?( n ) and not e == Set[n]
         end
         node_paths.each do |e|
            sum += dists[e]
         end
         average_length[n] = sum / node_paths.size.to_f
      end
      #p average_length
      average_length
   end
   def mean_average_shortest_path
      total = average_shortest_path.keys.inject(0){|sum,n|
         sum+=average_shortest_path[n]
      }
      total / size
   end

   # warshal-floyd
   # cf. http://www.astahost.com/Floyd-Warshall-Shortest-Path-Graphs-t17498.html
   Infinity = 1.0 / 0.0
   def warshal_floyd_shortest_paths
      dists = {}
      nodes.each do |n1|
         nodes.each do |n2|
            dists[ Set[n1, n2] ] = ( n1 == n2 ) ? 0 : ( edges[n1].include?(n2) ) ? 1 : Infinity
            #pp dists
         end
      end
      nodes.each do |k|
         nodes.each do |i|
            next if i == k
            nodes.each do |j|
               next if j == k
               dist_ij = dists[ Set[i,j] ]
               dist_ik = dists[ Set[i,k] ]
               dist_kj = dists[ Set[k,j] ]
               if dist_ik+dist_kj < dist_ij
                  dists[ Set[i,j] ] = dist_ik+dist_kj
               end
            end
            #pp dists
         end
      end
      dists
   end
end

class DirectedGraph < Graph
   attr_reader :edges_from, :edges_to
   def initialize
      @nodes = Set.new
      @edges = {}
      @edges_from = {}	# 接続元ノード
      @edges_to = {}	# 接続先ノード
      @node_labels = {}
      @edge_labels = {}
      #STDERR.puts @nodes.inspect
   end
   def add_node( n, label = n )
      @nodes << n
      @node_labels[ n ] = label
      @edges[n] ||= Set.new
      @edges_from ||= Set.new
      @edges_to ||= Set.new
   end
   def add_edge( n1, n2, label = nil )
      @nodes << n1
      @nodes << n2
      @edges[n1] ||= Set.new
      @edges[n1] << n2
      @edges[n2] ||= Set.new
      @edges[n2] << n1
      @edge_labels[ Set[n1, n2] ] = label if label
      @edges_from[ n2 ] ||= Set.new
      @edges_from[ n2 ] << n1
      @edges_to[ n1 ] ||= Set.new
      @edges_to[ n1 ] << n2
   end
   # Graph#load_dot2 requires "dot" command.
   def self.load_dot2( io, normalize = false, root = false )
      #STDERR.puts f
      root_node = false
      pin, pout, perr, = *Open3.popen3( "dot", "-Tplain" )
      cont = io.read
      if cont[ 0, 3 ] == "\xEF\xBB\xBF"
         STDERR.puts "BOM detected."
         cont = cont[ 3..-1 ]
      end
      pin.print cont
      pin.close
      g = self.new
      pout.each do |line|
         # p line
         case line
         when /\Anode /
            node = Shellwords.shellwords( line.chomp )[1]
            node = node.normalize_ja if normalize
            label = Shellwords.shellwords( line.chomp )[6]
            label = label.normalize_ja if normalize
            if root and not root_node
               label = "root:" + label
               root_node = node
               g.root_node = node
               #p "root_node:"+root_node
            end
            g.add_node( node, label )
         when /\Aedge /
            data = Shellwords.shellwords( line.chomp )
            num = data[3].to_i
            # cf. http://graphviz.org/content/output-formats#dplain
            ## ( 6 == "edge", head, tail, n, style, and color )
            label = if data.size > ( 6 + 2*num )
                       data[-5]
                    else
                       nil
                    end
            if normalize
               data[1] = data[1].normalize_ja
               data[2] = data[2].normalize_ja
            end
            g.add_edge( data[1], data[2], label )
         else
            #p line
         end
      end
      pout.close
      err_msg = perr.read
      if not err_msg.empty?
         STDERR.puts err_msg
      end
      perr.close
      g
   end

   def to_dot( attr = {} )
      done = {}
      str = "digraph {\n"
      each_node do |n|
         escaped_n = escape( n )
         # node_attr = { :label => @node_labels[ n ] }
         if attr[n]
            attr_s = attr[n].keys.sort.map{|e| %Q|#{e}="#{attr[n][e]}"| }.join(",")
            str << "#{ escaped_n } [ #{attr_s} ]\n"
         end
         if edges_to[ n ]
            edges_to[ n ].each do |n2|
               escaped_n2 = escape( n2 )
               pair = Set[ n, n2 ]
               if attr[ pair ]
                  attr_s = attr[ pair ].keys.sort.map{|e| %Q|#{e}="#{attr[pair][e]}"| }.join(",")
                  str << "#{ escaped_n } -> #{ escaped_n2 } [ #{attr_s} ]\n"
               else
                  str << "#{ escaped_n } -> #{ escaped_n2 }\n"
               end
            end
         end
      end
      str << "}"
      str
   end

   private
   def escape( str )
      case str
      when /[\(\)\&\?\-\%\.\/]/, /\A\d/
         str = %Q["#{ str }"]
      end
      str
   end
end

if $0 == __FILE__
   require "pp"
   require "test/unit"
   class TC_graph_test < Test::Unit::TestCase
      def test_g_test
         # cf. http://www.tcn.zaq.ne.jp/akayu508/document/SmallWorld.pdf
         g = Graph.new
         ( 1..8 ).each do |i|
            g.add_node( i )
         end
         g.add_edge( 1, 2 )
         g.add_edge( 1, 3 )
         g.add_edge( 1, 4 )
         g.add_edge( 1, 5 )
         g.add_edge( 2, 3 )
         g.add_edge( 2, 4 )
         g.add_edge( 3, 4 )
         g.add_edge( 4, 6 )
         g.add_edge( 5, 7 )
         g.add_edge( 6, 7 )
         g.add_edge( 6, 8 )
         g.add_edge( 7, 8 )
         #p g

         assert_equal( 8, g.size )
         assert_equal( 1, g.get_components.size )
         assert_equal( "0.58333333", "%.08f" % g.clustering_coefficient )
         shortest_paths = g.warshal_floyd_shortest_paths
         #pp shortest_paths
         assert_equal( 1, shortest_paths[ Set[7,8] ] )
         assert_equal( 3, shortest_paths[ Set[1,8] ] )
         average_shortest_path = g.average_shortest_path
         assert_equal( "1.57142857", "%.08f" % average_shortest_path[1] )
         assert_equal( 1.75, g.mean_average_shortest_path )
      end

      def test_g_dot
         require "stringio"
         dot = <<-EOF
         1 -- 5
         1 -- 2
         1 -- 3
         1 -- 4
         2 -- 3
         2 -- 4
         3 -- 4
         4 -- 6
         5 -- 7
         6 -- 7
         6 -- 8
         7 -- 8
	 EOF
         g = Graph.load_dot( StringIO.new( dot ) )
         assert_equal( 8, g.size )
      end
   end
end
