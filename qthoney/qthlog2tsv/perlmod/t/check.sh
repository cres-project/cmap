#!/bin/bash

#usage: check.sh [directory]
# find (not recursively) log files from [directory] and check expected action is observed in them.
# if [directory] is omitted, ./data is used as default.
# filename must be 'action(_[0-9])+(_.+)?.log' in RegExp
# each log filename's postfix numbers sign corresponding action number
# and test script is looking to find them.
# trailing non number flagments are ignored, exept for 'fail', 'invalid' and 'skip'.
# if these special flagmens appears, the file is skipped as failure case data
#
# e.g.
#   filename: action_12.log => action number: 12
#   filename: action_12_3.log => action number: 12.3
#   filename: action_12_3_foo.log => action number: 12.3
#   filename: action_12_3.fail.log => skipped, failure case data
#   filename: foo.bar.log => skipped, not matched with filename format

PERL=/usr/bin/perl

TEST_ROOT=$(dirname $(readlink -f $0))
DIR_PERLMOD=$(dirname $TEST_ROOT)
DIR_DEFAULTDATA=data

if [ -n "$1" ]; then
    dir=$(readlink -f $1)
else
    dir=$DIR_DEFAULTDATA
fi

cd $TEST_ROOT
PERL5LIB=$DIR_PERLMOD $PERL test.pl $dir
