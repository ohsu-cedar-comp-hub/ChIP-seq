#!/bin/sh

###
### Build index for bowtie2 alignment
###

### Executable
BOWTIE=$BIOCODERS/Applications/bowtie2-build

### Arguments
DIR=$1           # Directory to write out everything
IN=$2            # Reference genome file
BASE=$3          # base name for output file

### File manipulation

### Test
echo "DIR: " $DIR
echo "IN: " $IN
echo "BASE: " $BASE

### Run bowtie
cd $DIR
cmd="$BOWTIE $IN $BASE"

echo $cmd
eval $cmd
