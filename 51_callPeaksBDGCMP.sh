#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
MACS2=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/macs2

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
$MACS2 bdgcmp \
	-t $DIR/$BASE\_treat_pileup.bdg \
	-c $DIR/$BASE\_control_lambda.bdg \
	-o $OUT/$BASE\_FE.bdg \
	-m FE
"

echo $cmd
eval $cmd


cmd="
$MACS2 bdgcmp \
	-t $DIR/$BASE\_treat_pileup.bdg \
	-c $DIR/$BASE\_control_lambda.bdg \
	-o $OUT/$BASE\_logLR.bdg \
	-m logLR \
	-p 0.00001
"

echo $cmd
eval $cmd
