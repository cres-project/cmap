#!/usr/bin/env ruby
# $Id: ext-graph-diff.rb,v 1.8 2010/06/08 09:08:44 masao Exp $

require "graph"
require "open3"
require "pp"

# Usage: ./ext-graph-diff.rb <___pre.dot> <___post.dot>
# ex. ./ext-graph-diff.rb tsub032_politics_2_pre.dot tsub032_politics_2_post.dot | nkf

pre  = Graph.load_dot2( open( ARGV[0] ), true )
post = Graph.load_dot2( open( ARGV[1] ), true )

puts "Pre-nodes\t#{ pre.size }"
puts "Post-nodes\t#{ post.size }"

nodes = {}
nodes[ :common ]  = pre.nodes & post.nodes
nodes[ :lost ] = pre.nodes - post.nodes
nodes[ :new ]   = post.nodes - pre.nodes

pre_e = pre.links_set
post_e = post.links_set
links = {}
links[ :common ] = pre_e & post_e
links[ :lost ] = pre_e - post_e
links[ :new ]   = post_e - pre_e
[ :common, :lost, :new ].each do |c|
   # for Nodes:
   puts [ "#{ c } nodes".capitalize,
          nodes[c].size,
          nodes[c].to_a.sort.join(", ") ].join("\t")
end

puts "Pre-links\t#{ pre.link_count }"
puts "Post-links\t#{ post.link_count }"
[ :common, :lost, :new ].each do |c|
   # for Links:
   puts [ "#{ c } links".capitalize,
          links[c].size,
          links[c].to_a.map{|e| "{#{e.to_a.sort.join(",")}}" }.sort.join(", ") ].join("\t")
end

puts "Pre-link-labels\t#{ pre.link_labels.size }"
puts "Post-link-labels\t#{ post.link_labels.size }"
common_link_labels = links[ :common ].select{|e| pre.link_labels[ e ] and post.link_labels[ e ] }
lost_link_labels = links[ :lost ].select{|e| pre.link_labels[ e ] }
lost_link_labels += links[ :common ].select{|e| pre.link_labels[ e ] and not post.link_labels[ e ] }
new_link_labels = links[ :new ].select{|e| post.link_labels[ e ] }
new_link_labels += links[ :common ].select{|e| post.link_labels[ e ] and not pre.link_labels[ e ] }
#p new_link_labels
#p links[ :common ].select{|e| post.link_labels[ e ] and not pre.link_labels[ e ] }
puts "Common-link-labels\t#{ common_link_labels.size }\t#{ common_link_labels.map{|e| "#{post.link_labels[e]}:{#{e.to_a.join(",")}}" }.to_a.sort.join(", ") }"
puts "Lost-link-labels\t#{ lost_link_labels.size }\t#{ lost_link_labels.map{|e| "#{pre.link_labels[e]}:{#{e.to_a.join(",")}}" }.to_a.sort.join(", ") }"
puts "New-link-labels\t#{ new_link_labels.size }\t#{ new_link_labels.map{|e| "#{post.link_labels[e]}:{#{e.to_a.join(",")}}" }.to_a.sort.join(", ") }"
