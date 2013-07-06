use strict;
use warnings;

my ($dir) = @ARGV;
$dir = defined($dir) ? "$dir/" : '';

my @files = <${dir}action_*.log>; # see: perldoc -f glob
my $ng = 0;
foreach my $f (@files){
    printf("%32s ",$f);

    ($f =~ /action_(.+)\.log$/) or die "huh?";
    my @params = split(/_/, $1);
    if($params[-1] eq 'fail' || $params[-1] eq 'invalid' || $params[-1] eq 'skip'){
	print "..skip\n";
	next;
    }

    pop(@params) while(int(@params) && !($params[-1] =~ /^\d+$/));
    unless(int(@params)){
	print "..skip\n";
	next;
    }
    my $num = join('.', @params);

    open(my $in, '-|', qq(perl ../logconv.pl --silent --dump $f)) or die $!;
    my $output = do{ local $/; <$in> };
    close($in);

    if($output =~ /'num' => '?$num'?/){
	print "..ok\n";
    }else{
	print "..NG!\n";
	$ng++;
    }
}
($ng) and die "$ng test failed!\n";
print "done.\n"
