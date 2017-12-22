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
	extras \
	FastQC \
	qc \
	reference

### Copy code

