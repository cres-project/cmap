#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# count su number in each session

require "./ext-session.rb"

sessions = load_logdata

sessions.keys.each do |sesid|
	session = sessions[ sesid ]
	units = []
	cur_data = []
	action_data = nil
	session.each do |data|
		if /search_/ =~ data[ 6 ]
			if action_data
				units << cur_data
			end
			cur_data = []
			action_data = data
		end
		cur_data << data
	end
	if action_data and not cur_data.empty?
		units << cur_data
	end
	units.each do |unit|
		last_time  = Time.parse( unit[ -1][12] )
		first_time = Time.parse( unit[ 0 ][12] )
		time = ( last_time - first_time ).to_f
		puts [ sesid, unit[0][6], time ].join( "\t" )
	end
end
