#!/bin/sh

### Run homer analysis for each of the different files

### Note that input file names must be structured like so:
### [sourceName]_[type]_[extraClassifier].[txt/bed]
### sourceName - so far either commonPeaks (overlap of both shared peak sets) or diffBind (result of differential analysis)
### type
   ### position - bed file using genomic positions as input
   ### entrezID - single column file with entrezIDs
   ### geneName - single column file with entrezIDs
### extra Classifier - so far doesn't have a purpose

IN=$1
OUT=$2

## Get file 
file=${IN##*/}

## Remove file extension
base=${file%.bed}
base=${base%.txt}

## Get output directory name
DIR=`echo $base | cut -d '_' -f 1`

## Get type
TYPE=`echo $base | cut -d '_' -f 2`

## Make output directory
CURROUT=$OUT/$DIR/$TYPE

## Make output directory
mkdir -p $CURROUT

## Update log and user
LOG=$OUT/runLog.txt
echo date > $LOG
echo "Current input file: " $IN >> $LOG
echo "Currently on: " $DIR

#cmd="findMotifs.pl $IN human $CURROUT >> $CURROUT/runLog.txt 2>&1"
cmd="findMotifsGenome.pl $IN hg38 $CURROUT -size 200"

## Update log and user
echo $cmd >> $LOG
echo $cmd

## Run command
eval $cmd
