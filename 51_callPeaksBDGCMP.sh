#!/bin/sh

###
### Run bedcmp subcommand to generate noise-subtracted tracks.
###

### Executable
MACS2=$BIOCODERS/Applications/anaconda2/bin/macs2

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

### Run macs2 bdgcmp using Fold Enrichment
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

### Run macs2 bdgcmp using log10 likelihood ratio
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
