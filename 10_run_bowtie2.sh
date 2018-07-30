#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

### Executable
BOWTIE=$BIOCODERS/Applications/anaconda2/bin/bowtie2

### Reference
REFDIR="$BIOCODERS/DataResources/Genomes/hg38/release-87/bowtie2"

### Echo information to stderr
echoerr() { printf "%s\n" "$*" >&2; }

### Arguments
IN=$1
REF=$2
OUT=$3

### File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%_L00*}

### Test
echo "IN: " $IN
echo "REF DIRECTORY: " $REFDIR
echo "REF BASE: " $REF
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE

### Echo file name to stderr
echoerr $BASE

### Run bowtie
cd $DIR
cmd="$BOWTIE -p 4 -x $REFDIR/$REF -U $IN -S $OUT/$BASE.sam"

echo $cmd
eval $cmd
