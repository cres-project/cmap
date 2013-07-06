package actions;

use strict;
use warnings;

use utf8;

use Exporter qw/import/;
our @EXPORT_OK = qw/$actions/;

use URI;
use XML::LibXML;
use serps;

use constant RegExp_AnythingOK => '.*';

my @serps_url = map{ $_->{base_url} }(@{$serps::serps});

sub isSameTab{
    my ($a, $b) = @_;
    return ($a->{tab_id} eq $b->{tab_id});
};
sub isActionTail{ # check event is tail event of an action
    my ($event, $type) = @_;

    return (defined($event->{':action'}) &&
	    $event->{':action'}->{events}->[-1] eq $event);
};

sub cond_pageshow{ # default pageshow event rule
    my ($event, $members, $events) = @_;
    foreach(reverse(@$members)){
	next unless($_->{eventType} eq 'http_req');

	return ($_->{requestURI} eq $event->{pageshow_url});
    }
};

sub extra_bookmarkTitle{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    foreach(@$members){
	return { ':bookmark_title' => $_->{title} }
	  if(defined($_->{target_id}) && $_->{target_id} eq 'Browser:AddBookmarkAs');
    }
};
sub extra_link{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    foreach(@$members){
	next unless($_->{eventType} eq 'click');

	if(defined($_->{anchor_outerHTML}) && length($_->{anchor_outerHTML})){
	    my $dom = XML::LibXML->load_html(string => $_->{anchor_outerHTML});

	    my $text = $dom->findvalue('//img/@title');
	    $text = $dom->findvalue('//img/@alt') unless(length($text));
	    $text = $dom->findvalue('//a/text()') unless(length($text));

	    my $object = $dom->findvalue('//a/@name');
	    $object = $dom->findvalue('//a/@id') unless(length($object));

	    return { ':text' => $text,
		     ':href' => URI->new_abs($_->{anchor_href}, $_->{url}),
		     ':object' => $object,
		   };
	}
    }
}
sub extra_submit{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    foreach(@$members){
	next unless($_->{eventType} eq 'submit');

	my $uri = URI->new();
	$uri->query($_->{submit_data});
	my $params = { $uri->query_form() };

	use Data::Dumper;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;
	$params = Dumper($params);
	utf8::decode($params);

	return { ':href' => URI->new_abs($_->{form_action}, $_->{url}),
		 ':object' => defined($_->{form_name}) ? $_->{form_name} : $_->{form_id},
		 ':form_params' => $params,
	       };
    }
};
sub extra_pageshowURL{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    foreach(reverse(@$members)){ # get url from latest pageshow event
	next unless($_->{eventType} eq 'pageshow');
	return { ':href' => $_->{url} };
    }
}
sub extra_change{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    foreach(reverse(@$members)){
	next unless($_->{eventType} eq 'TabSelect');
	return { ':href' => $_->{tab_url} };
    }
};
sub extra_find{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    return { ':object' => $post->{find_text} };
};
sub extra_copy{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    return { ':object' => $post->{clipboard_toString} };
};
sub extra_contextAnchorHref{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    return { ':object' => URI->new_abs($members->[0]->{anchor_href}, $members->[0]->{url}) };
};
sub extra_contextImageSrc{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    my $dom = XML::LibXML->load_html(string => $members->[0]->{outerHTML});
    return { ':object' => URI->new_abs($dom->findvalue('//img/@src'), $members->[0]->{url}) };
};
sub extra_close{
    my ($action, $first, $pre, $post, $members, $def) = @_;

    return { ':object' => $post->{tab_id} };
};


our $actions =
  [
#   # ACTION SPEC SAMPLE
#   { num => 100,
#     label => 'sample-event',
#     events => [{ ':type' => 'click',
#		  target_id => '^Click ME.+$',
#		  foo => 'regexp_matches_with_foo',
#		  bar => '^multiple-condition-available$',
#		},
#		{ ':type' => 'with-custom',
#		  ':cond' => sub{
#		      my $conditon_OK = ....;
#		      return $conditon_OK ? 1 : undef;
#		  },
#		},
#		{ ':type' => 'same-tab?',
#		  # this event must be raised in other tab
#		  # different from one in which previous 2 events were raised.
#		  # if this is not set, events raised only from same tab are checked
#		  # to skip this check, set :othertab => 0
#		  ':othertab' => 1,
#
#		  # if event must be next to previous event (not include any event between them)
#		  # set :contiguous => 1
#		  ':contiguous' => 1,
#		}
#	       ],
#     # you can set action's priority. if not set, it is set to count(events) x 10 automatically
#     # this came from: longer event sequence means detailed action specification
#     # if same priority, faster definition is prior in this list
#     priority => -1, # of course, negative value is acceptable
#
#     # if you have some reason not to output this action, set 'suppress' to 1
#     # this action should be picked up as other actions, but not outputed
#     suppress => 1,
#   },

   { num => 1,
     label => 'cue',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		},
		{ ':type' => 'command',
		  target_label => '^Show Cue$',
		  ':contiguous' => 1,
		},
	       ],
   },

#   # 2: NOT OBSERVED
#   { num => 2,
#     label => 'start',
#     events => [{ ':type' => 'command',
#		  target_id => '^LogTB-Start-Button$',
#		},
#	       ],
#     init => 1,
#   },

   # 3: spec says CAN'T OBSERVE, but can
   { num => 3,
     label => 'start',
     events => [{ ':type' => 'init_qth',
		},
	       ],
     init => 1,
   },

   { num => 4, # &5
     label => 'start',
     events => [{ ':type' => 'init_qth',
		},
		{ ':type' => 'onExitPrivateBrowsing',
		},
	       ],
     init => 1,
   },

   { num => 6,
     label => 'end',
     events => [{ ':type' => 'click',
		  target_id => '^LogTB-Pause-Button$',
		},
		{ ':type' => 'command',
		  target_id => '^LogTB-Pause-Button$',
		  ':contiguous' => 1,
		},
	       ],
   },

   { num => 7,
     label => 'end',
     events => [{ ':type' => 'click',
		  target_id => '^menu_FileQuitItem$'
		},
		{ ':type' => 'command',
		  target_id => '^cmd_quitApplication$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 7.1, # menu -> shortcut key
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 88,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_quitApplication$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 8, # closing window from menu
     label => 'end',
     events => [{ ':type' => 'click',
		  target_id => '^menu_closeWindow$'
		},
		{ ':type' => 'command',
		  target_id => '^cmd_closeWindow$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 8.1, # closing last tab from menu
     label => 'end',
     events => [{ ':type' => 'click',
		  target_id => '^menu_close$'
		},
		{ ':type' => 'command',
		  target_id => '^cmd_close$',
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 8.2, # closing window from menu (shortcut key)
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 68,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_closeWindow$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 8.3, # closing window Ctrl+Shift^w
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 87,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && $event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^cmd_closeWindow$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 8.4, # closing last tab from menu (shortcut key)
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_close$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 9,
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 87, # Ctrl^w
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^cmd_close$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 10,
     label => 'end',
     events => [{ ':type' => 'onCloseWindow',
		},
	       ],
   },

   { num => 11,
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 115, # Alt^F4
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return ($event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && !$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'onCloseWindow',
		  ':contiguous' => 1,
		},
	       ],
   },

   { num => 12,
     label => 'end',
     events => [{ ':type' => 'click',
		  target_id => '^privateBrowsingItem$',
		},
		{ ':type' => 'command',
		  target_id => '^Tools:PrivateBrowsing$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabClose',
		},
		{ ':type' => 'TabSelect',
		  ':contiguous' => 1,
		  ':othertab' => 1, # here, tab changes.
		},
		{ ':type' => 'onEnterPrivateBrowsing',
		},
	       ]
   },

   { num => 12.1,
     priority => 49, # lower than num:13
     label => 'end',
     events => [{ ':type' => 'keydown',
		  keycode => 80,
		},
		{ ':type' => 'command',
		  target_id => '^Tools:PrivateBrowsing$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabClose',
		},
		{ ':type' => 'TabSelect',
		  ':contiguous' => 1,
		  ':othertab' => 1, # here, tab changes.
		},
		{ ':type' => 'onEnterPrivateBrowsing',
		},
	       ]
   },

   { num => 13,
     label => 'end',
     events => [
		{ ':type' => 'keydown',
		  keycode => 80, # Ctrl+Shift^P
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && $event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Tools:PrivateBrowsing$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabClose', # this action includes tab change sequence
		},
		{ ':type' => 'TabSelect',
		  ':contiguous' => 1,
		  ':othertab' => 1, # here, tab changes.
		},
		{ ':type' => 'onEnterPrivateBrowsing',
		},
	       ]
   },

   { num => 15, # type A, keyboard-shortcut driven: Ctrl^D -> 'Done' button
     label => 'bookmark',
     events => [{ ':type' => 'keydown',
		  keycode => 68, # Ctrl^D
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^editBookmarkPanelDoneButton$',
		},
	       ],
     extra => \&extra_bookmarkTitle,
   },

   { num => 15.1, # type A, menu driven: menu 'add bookmark' -> 'Done' button
     label => 'bookmark',
     events => [{ ':type' => 'click',
		  target_id => '^menu_bookmarkThisPage$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^editBookmarkPanelDoneButton$',
		},
	       ],
     extra => \&extra_bookmarkTitle,
   },

   { num => 15.2, # type X(cancel), keyboard-shortcut driven: Ctrl^D -> 'Cancel' button
     suppress => 1,
     label => '-bookmark',
     events => [{ ':type' => 'keydown',
		  keycode => 68, # Ctrl^D
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^editBookmarkPanelDeleteButton$',
		},
	       ],
   },

   { num => 15.3, # type X(cancel), menu driven: menu 'add bookmark' -> 'Cancel' button
     suppress => 1,
     label => '-bookmark',
     events => [{ ':type' => 'click',
		  target_id => '^menu_bookmarkThisPage$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^editBookmarkPanelDeleteButton$',
		},
	       ]
   },

   { num => 15.4, # type B, keyboard-shortcut driven: just Ctrl^D, skip clicking 'Done'
     label => 'bookmark',
     events => [{ ':type' => 'keydown',
		  keycode => 68, # Ctrl^D
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_bookmarkTitle,
   },

   { num => 15.5, # type B, menu driven: just click menu 'add bookmark', skip clicking 'Done'
     label => 'bookmark',
     events => [{ ':type' => 'click',
		  target_id => '^menu_bookmarkThisPage$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_bookmarkTitle,
   },

   { num => 15.6, # type X(cancel), keyboard-shortcut driven: Ctrl^D -> ESC
     suppress => 1,
     label => '-bookmark',
     events => [{ ':type' => 'keydown',
		  keycode => 68, # Ctrl^D
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => 27,
		},
		{ ':type' => 'command',
		  target_id => '^key_stop$',
		},
	       ],
   },

   { num => 15.7, # type X(cancel), menu driven: menu 'add bookmark' -> ESC
     suppress => 1,
     label => '-bookmark',
     events => [{ ':type' => 'click',
		  target_id => '^menu_bookmarkThisPage$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:AddBookmarkAs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => 27,
		},
		{ ':type' => 'command',
		  target_id => '^key_stop$',
		},
	       ]
   },


   # pending: specification unclear
   # num:69 takes same event sequence with 169/load. no difference to identify them
#   { num => 69,
#     priority => 0,
#     label => 'jump',
#     events => [{ ':type' => 'OnHistoryNewEntry',
#		},
#		{ ':type' => 'pageshow'
#		},
#	       ]
#   },

   { num => 70, # all type of link-click action (click, Ctrl^click, Shift^click)
     label => 'link',
     events => [{ ':type' => 'click',
		  # when clicking <a> or <a> tagged html element, attr 'anchor_href' appears
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':othertab' => 0, # both same/different tab is OK
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $url = URI->new_abs($members->[-1]->{anchor_href},
					     $members->[-1]->{url});
		      return (defined($url) && $url eq $event->{requestURI});
		  },
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_link,
   },

   { num => 71, # all type of link-ENTER action (ENTER, Ctrl^ENTER, Shift^ENTER)
     label => 'link',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'click',
		  # when clicking <a> or <a> tagged html element, attr 'anchor_href' appears
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':othertab' => 0, # both same/different tab is OK
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $url = URI->new_abs($members->[-1]->{anchor_href},
					     $members->[-1]->{url});
		      return (defined($url) && $url eq $event->{requestURI});
		  },
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_link,
   },

   { num => 72,
     label => 'link',
     events => [{ ':type' => 'click',
		  # when clicking <a> or <a> tagged html element, attr 'anchor_href' appears
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => ['^context-openlinkintab$', '^context-openlink$',
				'^tm-openinverselink$'],
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => ['^context-openlinkintab$', '^context-openlink$',
				'^tm-openinverselink$'],
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':othertab' => 1,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $url = URI->new_abs($members->[0]->{anchor_href},
					     $members->[0]->{url});
		      return (defined($url) && $url eq $event->{requestURI});
		  },
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_link,
   },
   { num => 72.1, # contextmenu -> shortcut
     label => 'link',
     events => [{ ':type' => 'click',
		  # when clicking <a> or <a> tagged html element, attr 'anchor_href' appears
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => [84, 87, 70],
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => ['^context-openlinkintab$', '^context-openlink$',
				'^tm-openinverselink$'],
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':othertab' => 1,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $url = URI->new_abs($members->[0]->{anchor_href},
					     $members->[0]->{url});
		      return (defined($url) && $url eq $event->{requestURI});
		  },
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_link,
   },

   # 73: pending: specification is unclear

   { num => 75,
     label => 'submit',
     events => [{ ':type' => 'click',
		  target => 'HTMLInputElement',
		  'type' => ['^submit$', '^image$'],
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_submit,
   },

   { num => 76,
     label => 'submit',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'click',
		  target => 'HTMLInputElement',
		  'type' => ['^submit$', '^image$'],
		  ':contiguous' => 1,
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_submit,
   },

   { num => 81, # matches: kakaku.com, yahoo, goo and bing
     label => 'search',
     events => [{ ':type' => 'click',
		  target => 'HTMLInputElement',
		  'type' => ['^submit$', '^image$'],
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_submit,
   },

   { num => 81.1, # start with ENTER
     label => 'search',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'click',
		  target => 'HTMLInputElement',
		  'type' => ['^submit$', '^image$'],
		  ':contiguous' => 1,
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_submit,
   },

   { num => 81.2, # space ALC custom A (button click)
     label => 'search',
     events => [{ ':type' => 'click',
		  target => 'HTMLInputElement',
		  'type' => '^button$',
		},
		{ ':type' => 'http_req',
		  requestURI => '^http://eow\.alc\.co\.jp/search\?q=([^/]+)',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     # no submit event. can't get extra
   },
   { num => 81.3, # space ALC custom B (submit by ENTER)
     label => 'search',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => '^http://eow\.alc\.co\.jp/search\?q=([^/]+)',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_submit,
   },

   { num => 81.4, # google.jp custom A (button click)
     label => 'search',
     events => [{ ':type' => 'click',
		  # different forms are used in top and search-result page
		  target => [qw(HTMLInputElement HTMLButtonElement)],
		},
		{ ':type' => 'http_req',
		  requestURI => '^http://www\.google\.co\.jp/search',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     # no submit event. can't get extra
   },
   { num => 81.5, # google custom B (submit by ENTER)
     label => 'search',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'http_req',
		  requestURI => '^http://www\.google\.co\.jp/search',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     # no submit event. can't get extra
   },

   { num => 86, # matches: google, yahoo
     label => 'search',
     events => [{ ':type' => 'click',
		  target_id => '^context-searchselect$',
		},
		{ ':type' => 'command',
		  target_id => '^context-searchselect$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'http_req',
		  #requestURI => $serps::serps_url,
		  requestURI => \@serps_url,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_pageshowURL,
   },

   # 88: pending: specification is unclear

   { num => 89,
     label => 'jump',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		},
		{ ':type' => 'command',
		  target_id => '',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_pageshowURL,
   },

   { num => 90,
     # this action confrict to 70. set higher priority, default priority for length 3 is 30
     priority => 31,
     label => 'search',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $url = URI->new_abs($event->{anchor_href}, $event->{url});
		      foreach(@serps_url){
			  return 1 if($url =~ $_);
		      }
		      return;
		  },
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		  # ... how can we say this event is driven from previous event
		  # can add any reasonable conditions ?
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_pageshowURL,
   },

   { num => 91,
     # this action confrict to 90. set higher priority
     priority => 32,
     label => 'browse',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;

		      my $a = URI->new($event->{url});
		      my $b = URI->new_abs($event->{anchor_href}, $event->{url});
		      foreach(@{$serps::serps}){
			  if($b =~ /$_->{base_url}/){
			      # check current/next url are same other than query
			      return unless(URI->new_abs($a->path(), $a) eq
					    URI->new_abs($b->path(), $b));

			      # check current/next url's specified queries are same
			      my $qa = { $a->query_form() };
			      my $qb = { $b->query_form() };

			      foreach(@{$_->{observe_keys}}){
				  return unless((!defined($qa->{$_}) && !defined($qb->{$_})) ||
						(defined($qa->{$_}) && defined($qb->{$_}) &&
						 $qa->{$_} eq $qb->{$_}))
			      }
			      return 1;
			  }
		      }
		      return;
		  },
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		  # ... how can we say this event is driven from previous event
		  # can add any reasonable conditions ?
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_link,
   },

   { num => 92,
     # this action confrict to 81. set higher priority, default priority for length 4 is 40
     priority => 41,
     label => 'search',
     events => [{ ':type' => 'click',
		  target => 'HTMLInputElement',
		},
		{ ':type' => 'submit',
		  ':contiguous' => 1,
		  form_action => RegExp_AnythingOK,
		  url => RegExp_AnythingOK,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      my $action = URI->new_abs($event->{form_action}, $event->{url});
		      foreach(@{$serps::serps}){
			  return 1 if(defined($_->{preference_url}) &&
				      $action =~ /$_->{preference_url}/);
		      }
		      return;
		  },
		},
		{ ':type' => 'http_req',
		  requestURI => \@serps_url,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_pageshowURL,
   },

   { num => 93,
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 84, # Ctrl^T
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^cmd_newNavigatorTab$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'TabSelect',
		},
	       ]
   },

   { num => 94, # & 95
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		  target_id => ['^content$', '^menu_newNavigatorTab$'],
		},
		{ ':type' => 'command',
		  target_id => '^cmd_newNavigatorTab$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'TabSelect',
		},
	       ]
   },

   { num => 96,
     label => 'change',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		},
	       ],
     extra => \&extra_change,
   },

   { num => 97,
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		},
		{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		},
	       ],
     extra => \&extra_change,
   },

   # 101: pending: same manipulation to 72

   { num => 104,
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		  target_id => '^content$',
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 105,
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		  target_id => '^content$',
		},
		{ ':type' => 'command',
		  target_id => '^content$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 106,
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => RegExp_AnythingOK,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (48 <= $event->{keycode} && $event->{keycode} <= 57);
		  },
		},
		{ ':type' => 'command',
		  target_id => '^key_selectTab[0-9]+$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 107,
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 9, # Ctrl^Tab
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 107.1,
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 9, # Ctrl+Shift^Tab
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && $event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:ShowAllTabs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 108,
     label => 'change',
     events => [{ ':type' => 'click', # FIXME? include this event? this seems to be pre-event?
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		  #':othertab' => 1, # sometimes tabID changes at this timing ? unclear condition
		},
		{ ':type' => 'command',
		  original_target_id => '^context_closeOtherTabs$',
		},
		{ ':type' => 'TabSelect',
		  ':othertab' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   # pending: 109, no such function in devteam's Fx

   { num => 110,
     label => 'change',
     events => [{ ':type' => 'click',
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  original_target_id => '^context_undoCloseTab$',
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'TabSelect',
		},
	       ],
     extra => \&extra_change,
   },

   { num => 111, # from menu
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		},
		{ ':type' => 'command',
		  target_id => '^$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		},
	       ],
     extra => \&extra_change,
   },

   { num => 111.1, # Ctrl+Shift+T
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 84,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && $event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^History:UndoCloseTab$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  pageshow_url => '^about:blank$',
		  ':othertab' => 1,
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabSelect',
		},
	       ],
     extra => \&extra_change,
   },

   { num => 112, # from menu
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		},
		{ ':type' => 'command',
		  target_id => '^$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_change,
   },

   { num => 112.1, # Ctrl+Shift^N
     label => 'change',
     events => [{ ':type' => 'keydown',
		  keycode => 78,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && $event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^History:UndoCloseWindow$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  url => '^about:blank$',
		  ':othertab' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
     extra => \&extra_change,
   },

   # 113: FIXME? spec NOT clear. this action don't inclide TabSelect event
   { num => 113, # sidebar:history -> today (R-click) -> open all as tabs
     label => 'change',
     events => [{ ':type' => 'click', # caution: this event is NOT raised when shortcut key used
		  target_id => '^placesContext_openContainer:tabs$',
		},
		{ ':type' => 'command',
		  target_id => '^placesContext_openContainer:tabs$',
		  ':contiguous' => 1,
		},
	       ],
     # 'sidebar:bookmark -> open all', 'bookmark bar -> open all' also matches this
     extra => \&extra_change,
   },

   { num => 113.1, # menu:bookmark -> folder sub menu -> open all as tabs
     label => 'change',
     events => [{ ':type' => 'click',
		  target => 'XULElement',
		  target_id => '^$',
		},
		{ ':type' => 'command',
		  target_id => '^$',
		  target_label => '^タブですべて開く$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_change,
   },

   # * event leak checker
   # in spite of all actions above, 'TabSelect' event remains alone when this action is found
   # you should define more evident rules in this case
   { num => '113.x',
     priority => 0,
     label => 'change-leakcheck',
     events => [{ ':type' => 'TabSelect',
		},
	       ],
   },

   { num => 122,
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 191,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && !$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => '_find',
		},
	       ],
     extra => \&extra_find,
   },

   { num => 122.1,
     label => 'find',
     events => [{ ':type' => '_find',
		  ':cond' => sub{
		      # additional rule:
		      # this action should follow another 'quick find'(122.1 or 122)
		      my ($event, $members, $events) = @_;
		      return undef unless($event->{':pos'} > 0);
		      for(my $i = $event->{':pos'}-1; $i >= 0; $i--){
			  if(defined($events->[$i]->{':action'})){
			      next if($events->[$i]->{':action'}->{def}->{num} == 122.1);
			      return ($events->[$i]->{':action'}->{def}->{num} == 122);
			  }
		      }
		  },
		},
	       ],
     extra => \&extra_find,
   },

   { num => 123,
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 71,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      if(!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			 !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl}){

			  # additional rule:
			  # this action should follow another 'find'(122 - 123)
			  my ($event, $members, $events) = @_;
			  return undef unless($event->{':pos'} > 0);
			  for(my $i = $event->{':pos'}-1; $i >= 0; $i--){
			      if(defined($events->[$i]->{':action'})){
				  return ($events->[$i]->{':action'}->{def}->{label} eq 'find' &&
					  ($events->[$i]->{':action'}->{def}->{num} =~ /^12[23]/));
			      }
			  }
		      }
		  },
		},
		{ ':type' => 'command',
		  target_id => '^cmd_findAgain$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 124,
     label => 'find',
     events => [{ ':type' => 'command',
		  target_id => '^cmd_find$',
		},
		{ ':type' => '_find',
		},
	       ],
     extra => \&extra_find,
   },

   { num => 124.1,
     label => 'find',
     events => [{ ':type' => '_find',
		  ':cond' => sub{
		      # additional rule:
		      # this action should follow another 'find'(124.1 or 124)
		      my ($event, $members, $events) = @_;
		      return undef unless($event->{':pos'} > 0);
		      for(my $i = $event->{':pos'}-1; $i >= 0; $i--){
			  if(defined($events->[$i]->{':action'})){
			      next if($events->[$i]->{':action'}->{def}->{num} == 124.1);
			      return ($events->[$i]->{':action'}->{def}->{num} == 124);
			  }
		      }
		  },
		},
	       ],
     extra => \&extra_find,
   },

   { num => 125, # Ctrl+F -> ENTER
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 13,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 126, # click 'find next'
     label => 'find',
     events => [{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^次を検索$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 126.1, # Alt^N
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 78,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return ($event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && !$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'mousedown',
		  ':contiguous' => 1,
		},
		{ ':type' => 'mouseup',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^次を検索$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 127, # click 'find previous'
     label => 'find',
     events => [{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^前を検索$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 127.1, # Alt^P
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 80,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return ($event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && !$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'mousedown',
		  ':contiguous' => 1,
		},
		{ ':type' => 'mouseup',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^前を検索$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 128, # click 'highlight'
     suppress => 1,
     events => [{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^すべて強調表示$',
		  ':contiguous' => 1,
		},
	       ],
   },

   { num => 128.1, # Alt^A
     suppress => 1,
     events => [{ ':type' => 'keydown',
		  keycode => 65,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return ($event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && !$event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'mousedown',
		  ':contiguous' => 1,
		},
		{ ':type' => 'mouseup',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^FindToolbar$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^FindToolbar$',
		  original_target_label => '^すべて強調表示$',
		  ':contiguous' => 1,
		},
	       ],
   },

   { num => 129, # Ctrl^G when quick search toolbar is NOT opened
     priority => 29,
     label => 'find',
     events => [{ ':type' => 'keydown',
		  keycode => 71,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^cmd_findAgain$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 130, # menu:edit -> find next
     label => 'find',
     events => [{ ':type' => 'click',
		  target_id => '^menu_findAgain$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_findAgain$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 130.1, # menu:edit -> find next (shortcut key)
     label => 'find',
     events => [{ ':type' => 'click',
		  target_id => '^edit-menu$',
		},
		{ ':type' => 'keydown',
		  keycode => 71,
		  ':contiguous' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_findAgain$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'onFindAgainCommand',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   { num => 131,
     label => 'find',
     events => [{ ':type' => 'drop',
		  target_toString => 'DOMStringList',
		},
		{ ':type' => '_find',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_find,
   },

   # 132: pending: specification is unclear

   { num => 133, # menu:cut/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^menu_cut$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_cut$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'cut',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 133.1, # menu:cut/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 84,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_cut$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'cut',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 134, # Ctrl^X
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 88,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'cut',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 135, # context menu:cut/click
     # note: 'context menu:cut/shortcut key' takes same events with 133.1
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^context-cut$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_cut$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'cut',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 136, # select urlbar -> menu:cut/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^menu_cut$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_cut$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_cut$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 136.1, # select urlbar -> menu:cut/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 84,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_cut$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_cut$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 137, # select urlbar -> Ctrl^X
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 88,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_cut$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 138, # select urlbar -> context menu:cut/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^urlbar$',
		},
		{ ':type' => 'command',
		  target_id => '^urlbar$',
		  original_target_label => '^切り取り$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_cut$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 138.1, # select urlbar -> context menu:cut/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 84,
		},
		{ ':type' => 'command',
		  target_id => '^urlbar$',
		  original_target_label => '^切り取り$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_cut$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

#
   { num => 143, # menu:copy/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^menu_copy$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_copy$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'copy',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 143.1, # menu:copy/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_copy$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'copy',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 144, # Ctrl^C
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'copy',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 145, # context menu:copy/click
     # note: 'context menu:copy/shortcut key' takes same events with 133.1
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^context-copy$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_copy$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'copy',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },
#
   { num => 146, # select urlbar -> menu:copy/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^menu_copy$',
		},
		{ ':type' => 'command',
		  target_id => '^cmd_copy$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_copy$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 146.1, # select urlbar -> menu:copy/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		},
		{ ':type' => 'command',
		  target_id => '^cmd_copy$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_copy$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 147, # select urlbar -> Ctrl^C
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_copy$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 148, # select urlbar -> context menu:copy/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  target_id => '^urlbar$',
		},
		{ ':type' => 'command',
		  target_id => '^urlbar$',
		  original_target_label => '^コピー$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_copy$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 148.1, # select urlbar -> context menu:copy/shortcut key
     label => 'copy',
     events => [{ ':type' => 'keydown',
		  keycode => 67,
		},
		{ ':type' => 'command',
		  target_id => '^urlbar$',
		  original_target_label => '^コピー$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'doCommand',
		  cmd => '^cmd_copy$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_copy,
   },

   { num => 153, # context menu:copy url/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^context-copylink$',
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-copylink$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextAnchorHref,
   },

   { num => 153.1, # context menu:copy url/shortcut key
     label => 'copy',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => 65,
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-copylink$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextAnchorHref,
   },

   { num => 154, # context menu:copy image's url/click
     label => 'copy',
     events => [{ ':type' => 'click',
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^context-copyimage$',
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-copyimage$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextImageSrc,
   },

   { num => 154.1, # context menu:copy image's url/shortcut key
     label => 'copy',
     events => [{ ':type' => 'click',
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => 79,
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-copyimage$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextImageSrc,
   },

   { num => 155, # context menu:send url/click
     label => 'copy',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'click',
		  target_id => '^context-sendlink$',
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-sendlink$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextAnchorHref,
   },

   { num => 155.1, # context menu:send url/shortcut key
     label => 'copy',
     events => [{ ':type' => 'click',
		  anchor_href => RegExp_AnythingOK,
		},
		{ ':type' => 'contextmenu',
		  ':contiguous' => 1,
		},
		{ ':type' => 'keydown',
		  keycode => 68,
		  ':first' => 1,
		},
		{ ':type' => 'command',
		  target_id => '^context-sendlink$',
		  ':contiguous' => 1,
		},
	       ],
     extra => \&extra_contextAnchorHref,
   },

   # 157: pending: specification is unclear
   # is this possible? catching a glimpse of event sequence, I'd say noway..

   { num => 169,
     label => 'load',
     events => [{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':cond' => sub{
		      # additional rule:
		      # this event should be just after 'start' action
		      my ($event, $members, $events) = @_;
		      return undef unless($event->{':pos'} > 0);
		      my $prev = $events->[$event->{':pos'} - 1];
		      return (isSameTab($prev, $event) &&
			      isActionTail($prev) &&
			      $prev->{':action'}->{def}->{label} eq 'start');
		  },
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },
   { num => 169.1, # input url into address-bar and ENTER, etc.
     priority => 19,
     label => 'load', # lazy version
     events => [{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170, # click reload icon
     suppress => 1,
     events => [{ ':type' => 'click',
		  target_id => '^reload-button$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:ReloadOrDuplicate$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170.1, # menu:view -> menu:reload/click
     suppress => 1,
     events => [{ ':type' => 'click',
		  target_id => '^menu_reload$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:ReloadOrDuplicate$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170.2, # menu:view -> menu:reload/shortcut key
     # note: 'context menu:reload/shortcut key' takes same events with 170.2
     suppress => 1,
     events => [{ ':type' => 'keydown',
		  keycode => 82,
		},
		{ ':type' => 'command',
		  target_id => '^Browser:ReloadOrDuplicate$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170.3, # menu:view -> # context-menu:reload/click
     suppress => 1,
     events => [{ ':type' => 'click',
		  target_id => '^context-reload$',
		},
		{ ':type' => 'command',
		  target_id => '^Browser:ReloadOrDuplicate$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170.5, # F5
     suppress => 1,
     events => [{ ':type' => 'keydown',
		  keycode => 116,
		},
		{ ':type' => 'command',
		  target_id => '^Browser:Reload$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   { num => 170.6, # Ctrl^R
     suppress => 1,
     events => [{ ':type' => 'keydown',
		  keycode => 82,
		  ':cond' => sub{
		      my ($event, $members, $events) = @_;
		      return (!$event->{modifiers}->{alt} && !$event->{modifiers}->{shift} &&
			      !$event->{modifiers}->{meta} && $event->{modifiers}->{ctrl});
		  },
		},
		{ ':type' => 'command',
		  target_id => '^Browser:Reload$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'OnHistoryReload',
		  ':contiguous' => 1,
		},
		{ ':type' => 'http_req',
		  requestURI => RegExp_AnythingOK,
		  ':contiguous' => 1,
		},
		{ ':type' => 'pageshow',
		  ':cond' => \&cond_pageshow,
		},
	       ],
   },

   # 171 - 173: pending: specification is unclear

   { num => 177, # context-menu:close other tabs/click
     label => 'close',
     events => [{ ':type' => 'click',
		  target_id => '^content$',
		},
		{ ':type' => 'command',
		  original_target_id => '^context_closeOtherTabs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabClose',
		  ':othertab' => 1,
		},
	       ],
     extra => \&extra_close,
   },

   { num => 177.1, # context-menu:close other tabs/shortcut key
     label => 'close',
     events => [{ ':type' => 'keydown',
		  keycode => 79,
		},
		{ ':type' => 'command',
		  original_target_id => '^context_closeOtherTabs$',
		  ':contiguous' => 1,
		},
		{ ':type' => 'TabClose',
		  ':othertab' => 1,
		},
	       ],
     extra => \&extra_close,
   },

   { num => 177.2, # alone TabClose event trailing another change/close action
     label => 'close',
     events => [{ ':type' => 'TabClose',
		  ':cond' => sub{
		      # additional rule:
		      # this action should follow another change/close action
		      my ($event, $members, $events) = @_;
		      return undef unless($event->{':pos'} > 0);
		      for(my $i = $event->{':pos'}-1; $i >= 0; $i--){
			  if(defined($events->[$i]->{':action'})){
			      return ($events->[$i]->{':action'}->{def}->{label} eq 'change' ||
				      $events->[$i]->{':action'}->{def}->{label} eq 'close');
			  }
		      }
		  },
		},
	       ],
     extra => \&extra_close,
   },

   # 178 - 179: pending: no TabClose observed in these operation

   # * event leak checker
   # in spite of all actions above, 'TabClose' event remains alone when this action is found
   # you should define more evident rules in this case
   { num => '177.x',
     priority => 0,
     label => 'close-leakcheck',
     events => [{ ':type' => 'TabClose',
		},
	       ],
   },
  ];
1;

