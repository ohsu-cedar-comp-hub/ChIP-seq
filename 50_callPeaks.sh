#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
MACS2=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/macs2

# Arguments
IN=$1
CTL=$2
OUT=$3
OUT2=$4

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}

CTLDIR=${CTL%/*}
CTLFILE=${CTL##*/}

BASE=${FILE%%.bam}

# Test
echo "IN: " $IN
echo "IN DIR: " $DIR
echo "IN FILE: " $FILE
echo ""
echo "CTL: " $CTL
echo "CTLDIR: " $CTLDIR
echo "CTLFILE: " $CTLFILE
echo ""
echo "BASENAME: " $BASE
echo ""
echo "OUT DIR: " $OUT
echo ""

# Run macs2
cd $DIR
cmd="
$MACS2 callpeak \
	--treatment $DIR/$FILE \
	--control $CTLDIR/$CTLFILE \
	--name $BASE \
	--outdir $OUT \
	--format BAM \
	-B \
	--SPMR \
	--qvalue 0.05 \
	--gsize hs \
	--verbose 4
"

echo $cmd
#eval $cmd

### Convert narrowpeaks file to bed
mkdir -p $OUT2

cmd="cut -f 1-5 $OUT/$BASE\_peaks.narrowPeak | sed 's/^/chr/' > $OUT2/$BASE\_narrowPeak.bed"

echo $cmd
eval $cmd

### Original command
# $MACS2 callpeak \
# 	--treatment $DIR/$FILE \
# 	--control $CTLDIR/$CTLFILE \
# 	--name $BASE \
#	--outdir $OUT \
# 	--format BAM \
#	--qvalue 0.05 \
#	--gsize hs \
#	--verbose 4
