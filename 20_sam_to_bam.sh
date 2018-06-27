#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2
SAMTOOLS=/home/exacloud/lustre1/BioCoders/Applications/samtools-1.3.1/bin/samtools

# Arguments
IN=$1
OUT=$2

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.*}

# Test
echo "IN: " $IN
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE

# Run samtools
cd $DIR

### Convert to bam
cmd="$SAMTOOLS view -bS $IN > $OUT/$BASE.bam"
echo "Convert to bam"
echo $cmd
eval $cmd
echo ""

### Remove old sam
echo "Remove original sam file"
cmd="rm $IN"
echo $cmd
eval $cmd
echo ""

### Sort
cmd="$SAMTOOLS sort -o $OUT/$BASE\_sorted.bam $OUT/$BASE.bam"
echo "Sort"
echo $cmd
eval $cmd
echo ""

### Remove old
cmd="mv $OUT/$BASE\_sorted.bam $OUT/$BASE.bam"
echo "Move"
echo $cmd
eval $cmd
echo ""
