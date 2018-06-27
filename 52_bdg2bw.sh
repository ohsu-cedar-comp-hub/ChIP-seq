#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
BDG2BW=/home/exacloud/lustre1/CompBio/users/hortowe/Sherman_80/DNA180319MS/misc/bdg2bw

# Ref
LEN=/home/exacloud/lustre1/CompBio/users/hortowe/Sherman_80/DNA180319MS/misc/hg38.len

# Arguments
IN=$1
#CTL=$2
OUT=$2

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}

#CTLDIR=${CTL%/*}
#CTLFILE=${CTL##*/}

BASE=${FILE%%.bam}

# Test
echo "IN: " $IN
echo "IN DIR: " $DIR
echo "IN FILE: " $FILE
echo ""
#echo "CTL: " $CTL
#echo "CTLDIR: " $CTLDIR
#echo "CTLFILE: " $CTLFILE
echo ""
echo "BASENAME: " $BASE
echo ""
echo "OUT DIR: " $OUT
echo ""

# Run macs2
cd $DIR
cmd="
$BDG2BW \
	$DIR/$BASE\_FE.bdg \
	$LEN
"

echo $cmd
eval $cmd


cmd="
$BDG2BW \
	$DIR/$BASE\_logLR.bdg \
	$LEN
"

echo $cmd
eval $cmd
