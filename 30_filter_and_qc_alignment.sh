#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executables
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/miniconda3/bin/bowtie2
SAMTOOLS=/home/exacloud/lustre1/BioCoders/Applications/samtools

# Arguments
IN=$1
OUT=$2

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.*}

# Test
echo "IN: " $IN
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE

echoerr() { printf "%s\n" "$*" >&2; }


###
### Get MapQ output ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###

# Print the 5th column of each sam record, which is the MapQ Score.
# 
cd $DIR
echoerr Mapq Filter QC
mkdir -p $OUT/qc/mapq_qc
$SAMTOOLS view $IN | awk -F '\t' '{print $5}' | sort | uniq -c > $OUT/qc/mapq_qc/$BASE.txt

###
### Filter Multi-Mappers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###

# -b means output is bam
# -q is for a minimum quality score. 10 in this case. 

echoerr Mapq Filter Unique Reads
mkdir -p $OUT/30_filtered_bam
$SAMTOOLS view -bq 10 $IN > $OUT/30_filtered_bam/$BASE.bam

###
### Collect Multi-Mappers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###

echoerr Mapq Filter Multi-mappers
mkdir -p $OUT/31_multi_map

# Grab header first
$SAMTOOLS view -H $IN > $OUT/31_multi_map/$BASE.sam
# If mapq is less than 10, read is a multi-mapper (Where did I get this number?). Add to header
$SAMTOOLS view $IN | awk -F '\t' '{if ($5 < 10) print $0}' >> $OUT/31_multi_map/$BASE.sam
# Convert back to bam
$SAMTOOLS view -bS $OUT/31_multi_map/$BASE.sam > $OUT/31_multi_map/$BASE.bam
# Remove sam
rm $OUT/31_multi_map/$BASE.sam
# Sort by read name
$SAMTOOLS sort -n -o $OUT/31_multi_map/$BASE.bam $OUT/31_multi_map/$BASE.bam

###
### Collect appropriate read IDs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###

# Get all of the read IDs from the bam output, then grab all of the sequences from the fastq file that DO NOT match.

echoerr Mapped Read IDs
mkdir -p $OUT/01_mapped_ids $OUT/02_unmapped_ids

$SAMTOOLS view $IN | awk -F '\t' '{print $1}' > $OUT/01_mapped_ids/$BASE.mapped.ids.txt


echoerr Unmapped Read Fastq
grep -v -F -A 3 --no-group-separator $OUT/01_mapped_ids/$BASE.mapped.ids.txt > $OUT/02_unmapped_fastqs/$BASE.fastq
