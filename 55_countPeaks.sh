#!/bin/sh

: '
Count the number of peaks in each sample - just wc -l of the narrowPeak file

Usage: 

sh $sdata/code/55_countPeaks.sh $sdata/data/50_peaks $sdata/data/qc/summary

'

### Arguments
IN=$1      # Directory containing MarkDuplicates log files
OUT=$2     # Directory to write output

### Create array of files and get number one less than length
FILES=(`ls $IN/*.narrowPeak`)
NUM=$(expr ${#FILES[*]} - 1)

### Make empty file with header
printf "File\tSample\tPeaks\n" > $OUT/numPeaks.txt

### Iterate over each
for i in $(eval echo "{0..$NUM}"); do

	### Get file and name
	CURRFULL=${FILES[$i]}
	CURRFILE=`basename $CURRFULL`
	CURRNAME=${CURRFILE%%_peaks.narrowPeak}

	### Print
	printf "Currently on %s\n\n" $CURRNAME

	### Get number of peaks
	CURRNUM=`wc -l $CURRFULL | cut -d ' ' -f 1`

	### Print File\tSample\tNumPeaks
	printf "%s\t%s\t%s\n" $CURRFILE $CURRNAME $CURRNUM >> $OUT/numPeaks.txt

done
