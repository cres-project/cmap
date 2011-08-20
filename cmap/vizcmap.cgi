#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id: vizcmap.cgi,v 1.8 2011/07/03 08:00:28 masao Exp $

require "cgi"
require "open3"
require "stringio"
require "fileutils"
require "erb"
require "digest/md5"

require "graph.rb"
require "merge.rb"
require "diff.rb"

class VizCMapApp
   attr_accessor :pre_dot, :post_dot
   attr_reader :format, :lang, :md5_id
   def initialize( cgi )
      @cgi = cgi
      @pre_dot  = cgi[ "pre_cmap"  ]
      @post_dot = cgi[ "post_cmap" ]
      @format = cgi[ "format" ]
      @md5_id = cgi[ "id" ]
      @md5_id = nil if @md5_id.empty?
      @lang = cgi[ "lang" ]
      @lang = "ja" if @lang.nil? or @lang.empty?
   end

   include CMapUtils
   def merge_dot( opts = [] )
      @merged_dot = to_merged_dot( StringIO.new( pre_dot ), StringIO.new( post_dot ) )
      if @merged_dot.size > 0
         dot_output_png( @merged_dot )
      end
      @statistics = statistics_merged_cmaps( StringIO.new( pre_dot ), StringIO.new( post_dot ) )
      @merged_dot
   end

   def dot_output_png( dot, dot_opts = [] )
      png = nil
      @md5 = Digest::MD5.hexdigest( dot )
      dot_tmpfile = File.join( "/tmp", "vizcmap#{ @md5 }.dot" )
      dot_png_tmpfile = File.join( "/tmp", "vizcmap#{ @md5 }.png" )
      if not File.exist?( dot_png_tmpfile )
         begin
            open( dot_tmpfile, "w" ) do |io|
               io.puts dot
            end
            STDERR.puts "dot generated."
            STDERR.puts "DOT_TMPFILE: #{ dot_tmpfile }"
            STDERR.puts "filesize: #{ File.size( dot_tmpfile ) }"
            STDERR.puts `/usr/bin/which dot`

            system( "dot -Tpng #{ dot_opts } #{ dot_tmpfile } > #{ dot_png_tmpfile }" )

            STDERR.puts "dot command finished."
            STDERR.puts "dot_opts: #{ dot_opts.inspect }"
            STDERR.puts "DOT_PNG_TMPFILE: #{ dot_png_tmpfile }"
            STDERR.puts "filesize: #{ File.size( dot_png_tmpfile ) }"
         end
      end
      read_png( @md5 )
   end

   def read_png( md5 )
      #p md5
      dot_png_tmpfile = File.join( "/tmp", "vizcmap#{ md5 }.png" )
      open( dot_png_tmpfile ) do |io|
         io.read
      end
   end

   include ERB::Util
   def expand_rhtml
      rhtml = open( "vizcmap.rhtml.#{ @lang }" ){|io| io.read }
      ERB.new( rhtml, nil, "<>" ).result( binding )
   end
end

begin
   cgi = CGI.new
   vizcmap = VizCMapApp.new( cgi )

   dot_opts = []
   if cgi.host == "cres.jpn.org" or ENV["HOME"] =~ /etk2/
      ENV["PATH"] += ":/home/etk2/bin"
      ENV["DOTFONTPATH"] = "/home/etk2/.fonts"
      dot_opts = %w[-Nfontname=ipamp -Efontname=ipamp]
   end
   #STDERR.puts dot_opts.inspect

   if vizcmap.md5_id and vizcmap.format == "png"
      print cgi.header( "image/png" )
      print vizcmap.read_png( vizcmap.md5_id )
   elsif vizcmap.pre_dot and not vizcmap.pre_dot.empty? and vizcmap.post_dot and not vizcmap.post_dot.empty?
      result = vizcmap.merge_dot( dot_opts )
      if vizcmap.format == "png"
         print cgi.header( "image/png" )
         print vizcmap.dot_output_png( result, dot_opts )
      else
         print cgi.header( "text/html; charset=utf-8" )
         print vizcmap.expand_rhtml
      end
   else
      DEFAULT_PRE_DOT  = open("test/test-0-pre.dot"){|io|  io.read }
      DEFAULT_POST_DOT = open("test/test-0-post.dot"){|io| io.read }
      print cgi.header( "text/html; charset=utf-8" )
      print vizcmap.expand_rhtml
   end
rescue Exception
   if cgi
      print cgi.header( 'status' => CGI::HTTP_STATUS['SERVER_ERROR'],
                        'type' => 'text/html' )
   else
      print "Status: 500 Internal Server Error\n"
      print "Content-Type: text/html\n\n"
   end
   puts "<h1>500 Internal Server Error</h1>"
   puts "<pre>"
   puts CGI::escapeHTML( "#{$!} (#{$!.class})" )
   puts ""
   puts CGI::escapeHTML( $@.join( "\n" ) )
   puts "</pre>"
   puts "<div>#{' ' * 500}</div>"
end
