#!/bin/bash

PERL=/usr/bin/perl

PROJECT_ROOT=$(dirname $(dirname $(readlink -f $0)))
FILE_THIS=$(basename $0)
DIR_PERLMOD="$PROJECT_ROOT/perlmod"

#
function fail(){
    if [ -n "$1" ]; then
	echo "$FILE_THIS [error] $1" 1>&2
    fi
    echo "use $FILE_THIS -h to see description" 1>&2
    exit $2
}
function usage(){
    cat << USAGE 1>&2
Usage: $FILE_THIS [options] [file...]
 * convert QT-Honey log to analyzed TSV format.

   parse QT-Honey log file(s) specified by parameter [file...],
   search defined actions and output in tsv format.
   when [file...] is omitted stdin is used to read input

 * options
	-l dirpath
		set directory for customized libraries
		when you want use customized serps.pm or actions.pm,
		place them in a directory and set this option like
		'-l /dir/to/customized/libraries'
		if this is not set or some of libraries doesn't exist,
		default libraries will be used
		to check which library is used, use --libs. see below
	-d filepath/dirpath
		set output file path. if not set, output is wrote to stdout.
		when input file is multiple, use this to set output root.
		output files will be placed under this directory
		with same relative path as input file path
		if you just want to know these generated file path, use -c
	-c
		input/output path checking mode
		set this to check input/output file path,
		no conversion and no output will be done
	-r
		recursive mode. conversion will be done to all files found by
		using 'find [file...] -name "*.log" -type f'
	-p
		make output file's parent directory if not exists
	-h
		show this help

 * script output options
	--indent
		add indent for each row
		easy to identify the tab in which an action is observed
	--silent
		no output. just run the action matching routine.
		this is good to test action definition
	--libs
		show loaded library path for serps.pm and actions.pm
	--dump
		dump events and actions' all inner object data
USAGE
    exit 0
}


src=()
options=()
for p in $@
do
    if [ -n "$_libs" ]; then
	libs=$p
	unset _libs
    elif [ "$p" == '-l' ]; then
	_libs=1
    elif [ -n "$_dst" ]; then
	dst=$p
	unset _dst
    elif [ "$p" == '-d' ]; then
	_dst=1
    elif [ "$p" == '-h' ]; then
	usage
    elif [ "$p" == '-c' ]; then
	check=1
    elif [ "$p" == '-r' ]; then
	recursive=1
    elif [ "$p" == '-p' ]; then
	parents=1
    elif [[ "$p" =~ "^--" ]]; then
	options=("${options[@]}" "$p")
    elif [[ "$p" =~ "^-" ]]; then
	usage
    else
	src=("${src[@]}" "$p")
    fi
done

if [ -n "$libs" ]; then
    if [[ ! -e "$libs" ]]; then
	fail "not exits: $libs" 1
    fi
    if [[ ! -d "$libs" ]]; then
	fail "not a directory: $libs" 1
    fi
fi

if [ -n "$recursive" ]; then
    if [[ "${#src[@]}" < 1 ]]; then
	src=(.)
    fi
    files=($(find ${src[@]} -name "*.log" -type f))
else
    files=(${src[@]})
fi

if [[ ${#files[@]} < 1 ]]; then
    # file not specified. read from stdin
    if [ -n "$dst" ]; then
	out=$dst
	if [[ ${#files[@]} > 1 ]]; then
	    out="${dst}/${f}.tsv"
	fi
	echo "(running) [stdin] > $out" 1>&2
    else
	echo "(running) [stdin]" 1>&2
    fi

    if [ -z "$check" ]; then

	if [ -n "$parents" ]; then
	    d=$(dirname $out)
	    mkdir -p $d
	fi

	if [ -n "$out" ]; then
	    PERL5LIB=$libs:$DIR_PERLMOD $PERL $DIR_PERLMOD/logconv.pl ${options[@]} > $out
	else
	    PERL5LIB=$libs:$DIR_PERLMOD $PERL $DIR_PERLMOD/logconv.pl ${options[@]}
	fi
	result=$?
	if [ $result != 0 ]; then
	    fail "script failed with code: $result" $result
	fi
    fi
fi

for f in ${files[@]}
do
    if [ ! -f $f ]; then
	echo "(skipped) not a regular file: $f" 1>&2
	continue
    fi

    if [ -n "$dst" ]; then
	out=$dst
	if [[ ${#files[@]} > 1 ]]; then
	    out="${dst}/${f}.tsv"
	fi
	echo "(running) $f > $out" 1>&2
    else
	echo "(running) $f" 1>&2
    fi

    if [ -n "$check" ]; then
	continue
    fi

    if [ -n "$parents" ]; then
	d=$(dirname $out)
	mkdir -p $d
    fi

    if [ -n "$out" ]; then
	PERL5LIB=$DIR_PERLMOD $PERL $DIR_PERLMOD/logconv.pl $f ${options[@]} > $out
    else
	PERL5LIB=$DIR_PERLMOD $PERL $DIR_PERLMOD/logconv.pl $f ${options[@]}
    fi
    result=$?
    if [ $result != 0 ]; then
	fail "script failed with code: $result" $result
    fi
done
