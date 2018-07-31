#!/bin/sh

### Run homer analysis for each of the different files
### findMotifs.pl is located at $BIOCODERS/Applications/anaconda2/bin/findMotifs.pl, so it should work if you added that to your path.

### Note that input file names must be structured like so:
### [sourceName]_[type]_[extraClassifier].[txt/bed]
### sourceName - so far either commonPeaks (overlap of both shared peak sets) or diffBind (result of differential analysis)
### type
   ### position - bed file using genomic positions as input
   ### entrezID - single column file with entrezIDs
   ### geneName - single column file with entrezIDs
### extra Classifier - so far doesn't have a purpose

IN=/path/to/homer/input/
OUT=/path/to/homer/output/

for file in `ls $IN`; do

    ## Get file (not needed when using `ls $IN` instead of $IN/*
    ## Doesn't change output though, so keeping for now.
    file=${file##*/}

    ## Remove file extension
    base=${file%.bed}
    base=${base%.txt}

    ## Get output directory name
    DIR=`echo $base | cut -d '_' -f 1`

    ## Get type
    TYPE=`echo $base | cut -d '_' -f 2`

    ## Construct input and output
    CURRIN=$IN/$file
    CURROUT=$OUT/$DIR/$TYPE

    ## Make output directory
    mkdir -p $CURROUT

    ## Update log and user
    LOG=$OUT/runLog.txt
    echo date > $LOG
    echo "Current input file: " $CURRIN >> $LOG
    echo "Currently on: " $DIR

    cmd="findMotifs.pl $CURRIN human $CURROUT >> $CURROUT/runLog.txt 2>&1"

    ## Update log and user
    echo $cmd >> $LOG
    echo $cmd

    ## Run command
    eval $cmd
done
