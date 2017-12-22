#!/bin/sh

### Make sure $sdata and $stool are set in .bash_paths

### Go to base directory
cd $sdata

### Make base directories
mkdir code data logs

### Make data directories
cd data
mkdir 	00_fastqs \
	01_mapped_ids \
	02_unmapped_fastqs \
	02_unmapped_ids \
	10_sam \
	20_bam \
	30_filtered_bam \
	31_multimap \
	40_convert \
	41_carpools \
	50_qc \
	extras \
	extras/md5 \
	FastQC 

### Copy code
cp -r $stool/* $sdata/code

### Make log directories
mkdir $sdata/code/logs
cd $sdata/code/logs
mkdir	00_md5 \
	01_unzip \
	10_bowtie \
	20_s2b \
	30_filter_and_qc \
	40_convert \
	50_error

### Copy ref library
cp $stool/reference/* $sdata/00_fastqs

