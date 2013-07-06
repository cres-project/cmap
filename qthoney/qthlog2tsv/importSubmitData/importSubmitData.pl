#!/usr/bin/perl

use Time::Local;
use JSON;

my $acceptableDelay = 100;

while(defined($ARGV[0]) && substr($ARGV[0], 0, 1) eq '-') {
    if($ARGV[0] eq '-d') {
	shift(@ARGV);
	$acceptableDelay = shift(@ARGV);
	unless(defined($acceptableDelay)) {
	    die "-d requires value";
	}
    }
}

my ($srcLogFilepath, $srcLog2Filepath, $dstLog2Filepath) = @ARGV;

my $outputToStdout = 0;
unless(defined($dstLog2Filepath)) {
    $outputToStdout = 1;
}

unless(defined($srcLog2Filepath)) {
    print "Usage: importSubmitData.pl\n";
    print "\t[-d acceptableDelay]\n";
    print "\t<src .log file> <src .log2 file> [dst .log2 file]\n";
    print "\n";
    print "\t-d DELAY\tacceptable delay msecs. for the same event\n";
    print "\t\t\tbetween .log & .log2 (default 100)\n";
    exit(1);
}

# --------------------------------
# scan submit from .log

open(my $srcLog, '<', $srcLogFilepath)
    or die "Cannot open src .log file: ".$srcLogFilepath;

my @submits;

while(<$srcLog>) {
    @fields = split(/\t/, $_);
    if(defined($fields[11]) && length($fields[11])) {
	my ($timeYMD, $tabID, $submitData) = ($fields[0], $fields[2], $fields[11]);
	my ($Y, $M, $D, $h, $m, $s, $ms) = ($timeYMD =~ /^(....)(..)(..)(..)(..)(..)\.(....)/);
	my $epochTime = timelocal($s, $m, $h, $D, $M-1, $Y);
	my $epochMS = $epochTime * 1e3 + $ms;

	push(@submits,
	     {
		 'epochMS'=>$epochMS,
		 'tabID'=>$tabID,
		 'submitData'=>$submitData
	     });
    }
}

close($srcLog);

# --------------------------------

open(my $srcLog2, '<', $srcLog2Filepath)
    or die "Cannot open src .log2 file: ".$srcLog2Filepath;


my $dstLog2;
if($outputToStdout) {
    $dstLog2 = *STDOUT;
} else {
    open($dstLog2, '>', $dstLog2Filepath)
	or die "Cannot open dst .log2 file: ".$dstLog2Filepath;
}


while(<$srcLog2>) {

    my $event;
    eval {
	$event = JSON::decode_json($_);
    };
    if($@) {
	warn "Malformed line";
	print $dstLog2 $_;
	next;
    }

    if(defined($event->{'eventType'}) && $event->{'eventType'} eq 'submit') {
	for(my $i = 0; $i < int(@submits); $i++) {
	    my $candidate = $submits[$i];

	    if(abs($candidate->{'epochMS'} - $event->{'timestamp'}) <= $acceptableDelay &&
	       $candidate->{'tabID'} eq $event->{'tab_id'}) {

		$event->{'submit_data'} = $candidate->{'submitData'};

		splice(@submits, $i, 1);
		last;
	    }
	}

	unless(defined($event->{'submit_data'})) {
	    warn "no submit data found";
	}

	print $dstLog2 JSON::encode_json($event), "\n";
    } else {
	print $dstLog2 $_;
    }
}

close($dstLog2);
close($srcLog2);

if(int(@submits) > 0) {
    warn "extra submit data remain";
}

exit(0);
