use strict;
use warnings;

use sort 'stable';
use JSON ();
use URI;
use Time::Piece ();
use Encode;

use Data::Dumper;

use serps qw/$serps/;
use actions qw/$actions/;

#====================
# subs
sub initActions{
    # check action not conflicted
    # and index actions to fasten process speed
    my ($indexed, $types) = @_;
    my $nums = {};

    foreach my $action (@$actions){
	# check num is unique
	defined($nums->{$action->{num}}) and
	  die "bad action config. duplicated action->{num}:$action->{num}";
	$nums->{$action->{num}} = 1;


	# normalize events' attribute conditions
	foreach my $event (@{$action->{events}}){
	    while(my ($key, $value) = each(%$event)){
		next if($key =~ /^:/);
		$event->{$key} = [ $value ] if(ref($value) eq '');
		(int(@{$event->{$key}}) > 0) or
		  die "bad action config. attribute condition is empty.".Dumper($action);
	    }
	    $types->{$event->{':type'}} = 1;
	}
	defined($action->{events}->[0]->{':othertab'}) and
	  die "bad action config. :othertab found in head event".Dumper($action);

	# set default priority
	$action->{priority} = int(@{$action->{events}}) * 10 unless(defined($action->{priority}));

	$action->{events}->[0]->{':head'} = 1;

	# register into action index
	my $type = $action->{events}->[0]->{':type'};
	push(@{$indexed->{$type}}, $action);
    }
    foreach(keys(%$indexed)){
	# sort by priority
	$indexed->{$_} = [ sort{ $b->{priority} <=> $a->{priority} }(@{$indexed->{$_}}) ];
    }
}

#==========
sub loadEvents{
    my ($events, $in, $types) = @_;

    while(my $line = <$in>){
	chomp($line);

	my $event;
	eval{
	    $event = JSON::decode_json($line);
	};
	if($@){
	    warn "* decode_json failed. line skipped.\n- $@\-- skipped line:\n$line\n";
	    next;
	}

	# sometimes, QTH outputs 'event_label' attribute insted of 'eventType'
	# this is obsoleted spec. just replace to new attribute
	$event->{eventType} = $event->{event_label}
	  if(!defined($event->{eventType}) && defined($event->{event_label}));

	# FIXME? really skip events that are out of observation?
	next unless(defined($types->{$event->{eventType}}));

	$event->{':pos'} = int(@$events);
	push(@$events, $event);
    }
}

#=====
sub searchActions{
    my ($events, $indexed) = @_;

    my $searched;
    foreach my $event (@$events){

	next unless(defined($indexed->{$event->{eventType}}));

	foreach my $action (@{$indexed->{$event->{eventType}}}){

	    # if already set action is prior, checking this event is done.
	    # because following actions have lower priority
	    last if(defined($event->{':action'}) && !defined($event->{':action'}->{overwrite}) &&
		    $action->{priority} < $event->{':action'}->{def}->{priority});

	    #
	    my $members = [];
	    my $pos_testing = $event->{':pos'} - 1;

	    foreach my $tester (@{$action->{events}}){
		$pos_testing++;

		for(; $pos_testing < int(@{$events}); $pos_testing++){

		    # head event must match at $event->{':pos'}
		    # for other events than head event, forward matching is allowed
		    unless(!$tester->{':head'} || $pos_testing == $event->{':pos'}){
			$pos_testing = int(@{$events});
			last;
		    }

		    my $testee = $events->[$pos_testing];

		    # check event is contiguous
		    if($tester->{':contiguous'}){
			unless($members->[-1]->{':pos'} + 1 == $testee->{':pos'}){
			    # not contiguous. skip to next action
			    $pos_testing = int(@{$events});
			    last;
			}
		    }

		    # check event is invoked in same/different tab
		    if($tester->{':othertab'}){
			next unless($members->[-1]->{tab_id} ne $testee->{tab_id});
		    }elsif(int(@$members) > 0 && !defined($tester->{':othertab'})){
			next unless($members->[-1]->{tab_id} eq $testee->{tab_id});
		    }

		    # check event type
		    next unless($tester->{':type'} eq $testee->{eventType});

		    # check other attributes
		    my $matched = 1;
		    foreach my $attr (keys(%$tester)){
			next if($attr =~ /^:/);

			my $_matched = 0; # flag: one of attribute conditions matches or not
			foreach my $condition (@{$tester->{$attr}}){
			    if((!defined($condition) && !defined($testee->{$attr})) ||
			       (defined($condition) && defined($testee->{$attr}) &&
				$testee->{$attr} =~ /$condition/)){
				$_matched = 1; # at least one condition is matched. OK
				last;
			    }
			}
			unless($_matched){
			    # none of conditions are matched. NG
			    $matched = 0;
			    last;
			}
		    }
		    next unless($matched);

		    # check custom condition
		    if(defined($tester->{':cond'})){
			next unless($tester->{':cond'}($testee, $members, $events));
		    }

		    # tester's all conditions are matched to testee attributes
		    # this can be an action step
		    # check next event
		    push(@$members, $testee);
		    last
		}

		last unless($pos_testing < int(@{$events}));
	    }

	    if($pos_testing < int(@$events)){ # action found
		my $found = { def => $action, events => $members };

		# check member events are not set to prior action
		foreach(@$members){
		    if(defined($_->{':action'}) && !defined($_->{':action'}->{overwrite})){
			my $_action = $_->{':action'}->{def};
			if($action->{priority} < $_action->{priority}){
			    # rejected. already set action is prior
			    $found = undef;
			    last;
			}
			if($action->{priority} == $_action->{priority}){
			    # already set action has same priority
			    # compare position distance and take shorter distance action
			    my $_members = $_->{':action'}->{events};
			    if($_members->[-1]->{':pos'} - $_members->[0]->{':pos'} <=
			       $members->[-1]->{':pos'} - $members->[0]->{':pos'}){
				# rejected. already set action has shorter distance
				$found = undef;
				last;
			    }
			}
		    }
		}
		if($found){
		    foreach(@$members){
			$_->{':action'}->{overwrite} = $found if(defined($_->{':action'}));
			$_->{':action'} = $found;
		    }
		    $searched = 1;
		}
	    }
	}
    }
    return $searched;
}

#=====
sub addAttributes{
    my ($events) = @_;

    my $tabs = {};
    my $currentTab = undef; # note: this is not focused tab. just in which events are ongoing
    my $tabNum = 0;
    my $loadID = 0;
    my $prev = undef; # $post of previous action

    foreach my $event (@$events){
	next unless(defined($event->{':action'}));
	next if(defined($event->{':action'}->{added}));
	next if(defined($event->{':action'}->{overwrite}));

	my $action = $event->{':action'};
	my $members = $action->{events};

	if($action->{def}->{init}){
	    # init tab state
	    $tabs = {};
	    $currentTab = undef;
	}

	# mark action's beggining event as 'first'
	my $first = $action->{first} = $members->[0];
	foreach(0..int(@{$action->{def}->{events}})-1){
	    if(defined($action->{def}->{events}->[$_]->{':first'})){
		$first = $action->{first} = $members->[$_];
		last;
	    }
	}

	# here, we take the action's tail event as a post state change event
	my $post = $action->{post} = $members->[-1];

	# take $first as a pre state change event
	# when $first and $post event are same, use $prev instead
	my $pre = $action->{pre} = ($first == $post) ? $prev : $first;

	my @states = ($post);
	unshift(@states, $pre) if($first != $post);

	# track tab change and url on $pre & $post
	foreach my $e (@states){

	    if(defined($currentTab) && $currentTab->{id} eq $e->{tab_id}){
		# no tab change
	    }elsif(defined($tabs->{$e->{tab_id}})){
		# tab changed to existing one
		$currentTab = $tabs->{$e->{tab_id}};
	    }else{
		# new tab opened
		$currentTab = { id => $e->{tab_id},
				num => ++$tabNum,
				url => defined($currentTab) ? $currentTab->{url} : undef,
				loadID => defined($currentTab) ? $currentTab->{loadID} : undef,
			      };
		$tabs->{$e->{tab_id}} = $currentTab;
	    }
	    unless(defined($currentTab->{url}) && $currentTab->{url} eq $e->{url}){
		$currentTab->{url} = $e->{url};
		$currentTab->{loadID} = ++$loadID;
	    }

	    $e->{':tab_num'} = $currentTab->{num};
	    $e->{':load_id'} = $currentTab->{loadID};
	}

	# additional url info on $pre & $post
	foreach my $e (@states){
	    $e->{':serp'} = 'non_serp';
	    foreach(@$serps){
		if($e->{url} =~ /^$_->{base_url}/){

		    $e->{':serp'} = 'serp';
		    $e->{':engine'} = $_->{search_label};

		    my $query = { URI->new($e->{url})->query_form() };
		    if($_->{keyword_type} eq 'parameter'){
			$e->{':keyword'} = Encode::decode('utf-8', $query->{$_->{keyword_key}});
		    }else{
			$e->{':keyword'} = Encode::decode('utf-8', $1);
		    }
		    $e->{':index'} = $query->{$_->{index_key}} if(defined($_->{index_key}));

		    last;
		}
	    }
	}

	# epoch / readable timestamp for $first
	my $sec = substr($first->{timestamp}, 0, -3);
	my $msec = substr($first->{timestamp}, -3);
	$action->{':epoch.sec'} = $sec;
	$action->{':epoch.msec'} = $msec;
	$action->{':epoch'} = "$sec.$msec";
	my $t = Time::Piece->localtime(Time::Piece->strptime($sec, '%s'));
	$action->{':timestamp'} = $t->strftime("%Y%m%d%H%M%S.$msec");

	# extra
	if(defined($action->{def}->{extra})){
	    my $extra = $action->{def}->{extra}->($action,
						  $first, $pre, $post, $members,
						  $action->{def});
	    if(defined($extra) && ref($extra) eq 'HASH'){
		foreach(keys(%$extra)){
		    defined($action->{$_})
		      and die "bad action config. extra attr key conflicted: $_";
		    $action->{$_} = $extra->{$_};
		}
	    }
	}

	# tear down
	$prev = $post;
	$action->{added} = 1;
    }
}
#=====
sub writeTSV{
    my ($events, $indent) = @_;

    print '#', join("\t", qw(time-y action
			     tab-id loadid url title type
			     postse postkw postno
			     selabl kw serpno
			     anchort o-url bookmk object form_params
			     postti postli
			     time-e dwell
			   )), "\n";

    my $prev = undef;
    foreach my $event (@$events){
	next unless(defined($event->{':action'}));
	next if($event->{':action'}->{def}->{suppress});
	next if(defined($event->{':action'}->{overwrite}));
	next unless($event == $event->{':action'}->{events}->[0]);

	my @columns;

	my $action = $event->{':action'};
	my $def = $action->{def};
	my $first = $action->{first};
	my $pre = $action->{pre};
	my $post = $action->{post};

	push(@columns, $action->{':timestamp'});
	push(@columns, $def->{label});

	push(@columns, $pre->{':tab_num'});
	push(@columns, $pre->{':load_id'});
	push(@columns, $pre->{url});
	push(@columns, $pre->{title});
	push(@columns, $pre->{':serp'});

	push(@columns, $post->{':engine'});
	push(@columns, $post->{':keyword'});
	push(@columns, $post->{':index'});

	push(@columns, $pre->{':engine'});
	push(@columns, $pre->{':keyword'});
	push(@columns, $pre->{':index'});

	push(@columns, $action->{':text'});
	push(@columns, $action->{':href'});
	push(@columns, $action->{':bookmark_title'});
	push(@columns, $action->{':object'});
	# always empty. current log doesn't have form information
	push(@columns, $action->{':form_params'});

	push(@columns, $post->{':tab_num'});
	push(@columns, $post->{':load_id'});

	push(@columns, $action->{':epoch'});
	if(defined($prev)){
	    my $_action = $prev->{':action'};
	    # to avoid rounding error, calc in integer for each sec/msec part
	    my $sec = $action->{':epoch.sec'} - $_action->{':epoch.sec'};
	    my $msec = $action->{':epoch.msec'} - $_action->{':epoch.msec'};
	    if($msec < 0){
		$sec -= 1;
		$msec += 1000;
	    }
	    push(@columns, sprintf("%d.%03d", $sec, $msec));
	}else{
	    push(@columns, '');
	}

	foreach(@columns){
	    $_ = '' unless(defined($_));
	    $_ =~ s/\t/ /g;
	}
	print join("\t", @columns), "\n";

	$prev = $event;
    }
}

#=====
sub dumpActions{
    my ($events) = @_;

    foreach my $event (@$events){
	next unless(defined($event->{':action'}));
	next if(defined($event->{':action'}->{overwrite}));
	next unless($event == $event->{':action'}->{events}->[0]);

	print "**SUPPRESSED** " if($event->{':action'}->{def}->{suppress});
	print Dumper($event);
    }
}

#====================
# main

# check option flags
my $flags = { -silent => undef,
	      -dump => undef,
	      -indent => undef,
	      -libs => undef,
	    };
foreach(reverse(0..$#ARGV)){
    if($ARGV[$_] =~ /^-(-?\w+)(=(.*))?$/ && exists($flags->{$1})){
	$flags->{$1} = defined($3) ? $3 : 1;
	splice(@ARGV, $_, 1);
    }
}

if($flags->{-libs}){
    print <<LIBS_INFO
serps	:$INC{'serps.pm'}
actions	:$INC{'actions.pm'}
LIBS_INFO
      ;
}

# phase: init indexed action table etc.
my $indexed = {}; # indexed actions
my $types = {}; # known action types
initActions($indexed, $types);

# phase: load logfile and decode as javascript event
my ($file_log) = @ARGV;
my $in;
if(defined($file_log)){
    open($in, '<', $file_log) or die "file open failed. $! :$file_log\n";
}else{
    open($in, '-') or die "stdin open failed. $!\n";
}
binmode(STDOUT, ':utf8');

my $events = [];
loadEvents($events, $in, $types);

close($in);

# phase: search actions using indexed action table
while(1){
    last unless(searchActions($events, $indexed));
}

# phase: add human readable attributes
addAttributes($events) unless($flags->{-silent});

# phase: output
writeTSV($events, $flags->{-indent}) unless($flags->{-silent});
dumpActions($events) if($flags->{-dump});
