#!/bin/sh

: '
Extract info from the MarkDuplicates output

Basically just removes the commented lines so it can be easily read by R.

Usage: 

sh $sdata/code/20_processDupLog.sh $sdata/data/41_remDupLog $sdata/data/qc/summary

'

### Arguments
IN=$1      # Directory containing MarkDuplicates log files
OUT=$2     # Directory to write output

### Create array of files and get number one less than length
FILES=(`ls $IN`)
NUM=$(expr ${#FILES[*]} - 1)

### Iterate over each
for i in $(eval echo "{0..$NUM}"); do

	### Get file and name
	CURRFILE=${FILES[$i]}
	CURRNAME=${CURRFILE%%.txt}

	### Print
	printf "Currently on %s\n\n" $CURRNAME

	### Subset file
	awk -F '\t' '{if (($0 !~ "^#") && ($0 !~ "^$")) print $0}' $IN/$CURRFILE > temp

	### Add sample name
	printf "Sample\n%s\n" $CURRNAME > temp2

	### Paste together
	paste temp2 temp > temp3

	### If first file, make new file with header, otherwise just append data
	if [ $i == 0 ]; then
		mv temp3 $OUT/dupSummary.txt
	else
		tail -1 temp3 >> $OUT/dupSummary.txt
	fi
	
	### Clean up
	rm temp*

done

