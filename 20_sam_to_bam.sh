#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/miniconda3/bin/bowtie2
SAMTOOLS=/home/exacloud/lustre1/BioCoders/Applications/samtools

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

$SAMTOOLS view -bS $IN > $OUT/$BASE.bam
