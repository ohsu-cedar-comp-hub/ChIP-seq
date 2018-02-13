#!/bin/sh

###
### Convert bam output into a matrix suitable for bias-reduction inputs
###

### As of 2017-7-27 this script outputs 2 sets of files. One compatible with Bcore Bias Reduction code, and another compatible with caRpools.
### 40_convert is Bcore
### 41_carpools is caRpools

### Also output so that 40_convert is tab-separated rather than space-sep

# Executable
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2
SAMTOOLS=/home/exacloud/lustre1/BioCoders/Applications/samtools

# Arguments
IN=$1
OUT=$2

# Outputs
OUT1=$2/40_convert
OUT2=$2/41_carpools

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.*}

# Test
echo "IN: " $IN
echo "OUT: " $OUT1
echo "OUT2: " $OUT2
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE

# Run samtools
cd $DIR

echo $IN
echo $OUT1/$BASE\_counts.txt

## Make empty file. Not sure if necessary...
touch $OUT1/$BASE\_counts.txt

## Print reference name, then sort and count
$SAMTOOLS view $IN | awk -F '\t' '{print $3}' | sort | uniq -c > $OUT1/$BASE\_counts.txt

## Convert space to tab and remove preceding spaces
awk -F ' ' -v OFS='\t' '{print $1, $2}' $OUT1/$BASE\_counts.txt > $OUT1/$BASE\_temp.txt

## Replcace
mv -f $OUT1/$BASE\_temp.txt $OUT1/$BASE\_counts.txt

## Create caRpools file
printf "id\tcount\n" > $OUT2/$BASE\_counts.txt

## Switch columns and append
awk -F '\t' -v OFS='\t' '{print $2, $1}' $OUT1/$BASE\_counts.txt >> $OUT2/$BASE\_counts.txt
