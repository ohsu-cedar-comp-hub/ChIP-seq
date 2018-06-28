#!/bin/sh

###
### Run MarkDuplicates from picard tools. Also remove them
###

### Notes - If REMOVE_DUPLICATES is set to false, duplicates will simply be marked and output files will be same size as input files.
###	    Duplicates are marked with a flag of 0x0400 (hexadecimal) and 1024 (decimal) for downstream filtering.

### Executable
PICARD=$BIOCODERS/Applications/picard-tools-2.9.0/picard.jar

### Arguments
IN=$1
OUT=$2
LOG=$3

### File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.*}

### Test
echo "IN: " $IN
echo "REF: " $REF
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE


### Run mark dups
cd $DIR

cmd="java -jar $PICARD MarkDuplicates REMOVE_DUPLICATES=true I=$DIR/$FILE O=$OUT/$BASE.bam M=$LOG/$BASE.txt"

echo $cmd
eval $cmd
