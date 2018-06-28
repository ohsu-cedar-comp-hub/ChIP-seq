#!/bin/sh

###
### Convert bedGraph to bigWig
###

### Executable
BDG2BW=/home/exacloud/lustre1/CompBio/users/hortowe/Sherman_80/DNA180319MS/misc/bdg2bw

### Ref
LEN=/home/exacloud/lustre1/CompBio/users/hortowe/Sherman_80/DNA180319MS/misc/hg38.len

### Arguments
IN=$1
OUT=$2

### File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.bam}

### Test
echo "IN: " $IN
echo "IN DIR: " $DIR
echo "IN FILE: " $FILE
echo ""
echo "BASENAME: " $BASE
echo ""
echo "OUT DIR: " $OUT
echo ""

### Convert Fold Enrichment
cd $DIR
cmd="
$BDG2BW \
	$DIR/$BASE\_FE.bdg \
	$LEN
"

echo $cmd
eval $cmd

### Convert log10 likelihood ratio
cmd="
$BDG2BW \
	$DIR/$BASE\_logLR.bdg \
	$LEN
"

echo $cmd
eval $cmd
