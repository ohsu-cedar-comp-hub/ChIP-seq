#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

### Executable
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2

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
echo "REF: " $REF
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE

### Echo file name to stderr
echoerr $BASE

### Run bowtie
cd $DIR
cmd="$BOWTIE -p 4 -x $REF -U $IN -S $OUT/$BASE.sam"

echo $cmd
eval $cmd
