#!/bin/sh

### Make sure $sdata and $stool are set in .bash_paths

### Make directory
mkdir -p $sdata

### Go to base directory
cd $sdata

### Make base directories
mkdir code data logs

### Make data directories
cd data
mkdir -p 00_fastqs \
	01_trim \
	02_trimLog \
	02_trimLog/trimLogProcessed \
	10_sam \
	20_bam \
	30_uniq_map \
	31_multi_map \
	32_unmapped_ids \
	33_good_reads \
	34_bad_reads \
	40_remDup \
	41_remDupLog \
	50_peaks \
	50.5_bedPeaks
	51_bdgcmp \
	52_bw \
	53_wigCorrelate \
	54_signalTrack \
	55_st_bdgcmp \
	56_st_bw \
	60_idr \
	70_phantom \
	qc \
	extras \
	extras/md5

### Copy code
cp -r $stool/* $sdata/code

### Make log directories
cd $sdata/logs
mkdir -p 00_md5 \
	01_unzip \
	02_trim \
	03_bowtieBuild \
	10_bowtie \
	20_s2b \
	30_filter_and_qc \
	40_remDup \
	50_callPeaks \
	51_callPeaksBDGCMP \
	52_bdg2bw \
	53_wigCorrelate \
	54_signalTrack \
	55_st_bdgcmp \
	56_st_bw \
	60_idr \
	61_peakPlot \
	70_phantom


