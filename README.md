PROCEDURE FOR ChIP-Seq
======================

Step-by-step instructions for how to analyze ChIP-Seq data starting from raw FASTQ files and ending with analysis-ready peak files.  

Most of the work in the pipeline is done by various scripts in the `code` directory (created by `setup.sh`). These scripts will be submitted to the Slurm job scheduler in "batch jobs" using the scripts located in the `sbatch` directory. Each "code" script has a corresponding "sbatch" script with the same numeric prefix (e.g. `code/00_process.md5.R` and `code/sbatch/00_sbatchmd5.sh`).  

A majority of the sbatch scripts are "array jobs", which means that one job is sent to the scheduler per file. If a tool is an array job, it will have `#SBATCH --array 1-n` as the last `#SBATCH` argument at the top of the script, where n is the number of individual files that need to be processed. Additionally, the output and error files created for each job will end in `_%A_%a.out` or `_%A_%a.err` for array jobs and `_%j.out` or `_%j.err` for non-array jobs.  

Each job submission will create an output and an error file that have a descriptive prefix denoting the tool it came from, along with the job or array id. These files will be generated in whichever directory you are currently in when you submit to Slurm. There is a qc directory with sub-directories for each step in the pipeline that are designed to hold these log files.  

In addition to the main processing steps, there are also some qc scripts that are housed in the `code/qc` directory. You will see them mentioned throughout the steps of the pipeline. They mainly parse different log outputs from the main tools and create qc plots for review.  

There are also a number of analysis scripts that have yet to be generalized and also have not been designed to be submitted to Slurm. They're located in `code/analysis`. 

SETUP
=====

1. Make sure that you have the following in your .bashrc, .bash_profile, or equivalent:  

   ```
   export sdata="/path/to/LIBXXXXXMS"
   export stool="/path/to/this/installation"
   export BIOCODERS="/path/to/BioCoders/"
   export R_LIBS_USER="$BIOCODERS/InstalledLibraries/R"
   export PATH="$PATH:$BIOCODERS/Applications/anaconda2/bin"
   ```
1. Double-check that R is pointing to the right directory by running the following:

   ```
   ~$ R
   > .libPaths()
   [1] "/home/exacloud/lustre1/BioCoders/InstalledLibraries/R"
   ```
   The path listed above should be the first result. You will likely have multiple paths listed after this one.  

1. Run `sh $stool/setup.sh` to create empty directories.  

1. Follow directions from MPSSR to transfer files from nix.  
   1. FastQC goes in $sdata/data/FastQC.  
   1. Reports, Stats, readme.txt go in $sdata/data/extras.  
   1. Fastq files go in $sdata/data/00_fastqs.  

1. Check Fastq transfer using md5 sums.  

   ```
   ~$ sbatch $sdata/code/sbatch/00_sbatchmd5.sh
   ~$ cd $sdata/data/00_fastqs
   ~$ diff calculated.md5.sums.txt md5sum.sorted.txt
   ~$ mv calculated.md5.sums.txt md5sum.sorted.txt md5sum.txt $sdata/data/extras/md5
   ~$ mv $sdata/code/sbatch/md5_* $sdata/logs/00_md5
   ```
   
1. Run multiqc on FastQC files.  

   ```
   ~$ MULTIQC=$BIOCODERS/Applications/anaconda2/bin/multiqc
   ~$ $MULTIQC $sdata/data/FastQC
   <copy files to local drive to view>
   ```

1. Unzip. (Not necessary, but useful to take a look at fastq files if you want).

   ```
   ~$ sbatch $sdata/code/sbatch/01_sbatchUnzip.sh
   ~$ mv $sdata/code/sbatch/unzip_* $sdata/logs/01_unzip
   ```

1. Trim adapter sequence, reformat log files, and make plots

   ```
   ~$ sbatch $sdata/code/sbatch/02_sbatchTrimSeq.sh
   ~$ mv $sdata/data/01_trim/*_report.txt $sdata/data/02_trimLog
   ~$ cd $sdata/02_trimLog
   ~$ for file in *_report.txt; do name=${file%%_L005*}; sh $sdata/code/qc/01_processTrimLog.sh $file $name trimLogProcessed/; done
   ~$ Rscript $sdata/code/qc/02_trimViz.R --summaryDir $sdata/data/qc/trimLogProcessed/summary/ --trimDistDir $sdata/data/qc/trimLogProcessed/trimDist --meta $sdata/meta/meta.txt --outDir $sdata/data/qc/plots/trimQC/
   ```

1. Create bowtie index.  

   ```
   ## Double check that $IN is the appropriate path
   ## Double check that $BASE is appropriate for your genome
   ~$ sbatch $sdata/code/sbatch/03_sbatchBowtieBuild.sh
   ```

ALIGNMENT PROCESSING
====================

1. Run bowtie2.  

   ```
   ~$ sbatch $sdata/code/sbatch/10_sbatchBowtie.sh
   ~$ mv $sdata/code/sbatch/bowtie2_* $sdata/logs/10_bowtie
   ```

1. Convert sam files to bam.  

   ```
   ~$ sbatch $sdata/code/sbatch/20_sbatchSam2Bam.sh
   ~$ mv $sdata/code/sbatch/s2b_* $sdata/logs/20_s2b
   ```

1. Filter data and get some QC. info.  
   1. Split - split into unmapped, multi-mapped, and uniquely-mapped. Further split into good and bad reads via MAPQ score.
      1. unmapped -          use `-f 4`
      1. multi-mapped -      use `-F 4` and grep for "XS:i:"
      1. unique-mapped -     use `-F 4` and inverse grep for "XS:i:"
   1. MapQ - print mapQ scores for each alignment (5th column of bam file)

   ```
   ~$ sbatch $sdata/code/sbatch/30_sbatchFilterQC.sh
   ~$ mv $sdata/code/sbatch/filterQC_* $sdata/logs/30_filter_and_qc
   ```

   1. Aggregate/reformat QC files

   ```
   ~$ Rscript $sdata/code/qc/10_bowtie_alignment_qc.R --inputDir $sdata/logs/10_bowtie --outDir $sdata/data/qc/summary/
   ~$ for dir in `ls $sdata/data/qc/*_mapq`; do Rscript $sdata/code/qc/11_bowtie_mapqDistr.R -i $sdata/data/qc/$dir -o $sdata/data/qc/summary -f "2,3,4,5"
   ```

   1. Make plots

   ```
   ~$ Rscript $sdata/code/qc/12_plot_alignment_qc.R --inputFile $sdata/data/qc/summary/bowtie2.alignment.QC.summary.txt \
						    --outDir $sdata/data/qc/plots/alignQC/ \
						    --treat 1 --type 2 --rep 3
   ~$ Rscript $sdata/code/qc/13_mapq_alignment_qc.R --uniqInputFile $sdata/data/qc/summary/uniq_mapq_summary.txt \
						    --multiInputFile $sdata/data/qc/summary/multi_mapq_summary.txt \
						    --treat 1 --type 2 --rep 3 --cutOff 10 
						    --outDir $sdata/data/qc/plots/alignQC/
   ```

1. Mark duplicates with picard tools, reformat log files for plotting, and plot.

   ```
   ~$ sbatch $sdata/code/sbatch/40_sbatchRemDup.sh
   ~$ mv $sdata/code/sbatch/remDup_* $sdata/logs/40_remDup
   ~$ sh $sdata/code/qc/20_processDupLog.sh $sdata/data/41_remDupLog $sdata/data/qc/summary
   ~$ Rscript $sdata/code/qc/21_plot_markDup_qc.R --inputFile $sdata/data/qc/summary/dupSummary.txt \
						  --outDir $sdata/data/qc/plots/alignQC/ \
						  --treat 1 --type 2 --rep 3
   ```

PEAK CALLING
============

1. Call peaks using MACS2 (following instructions from: https://github.com/taoliu/MACS/wiki/Build-Signal-Track)  
   1. `-B` tells MACS2 to store fragment pileup scores in bedGraph files.  
   1. `--SPMR` tells MACS2 to generate pileup signal of 'fragment pileup per million reads'.  
   1. `--qvalue 0.05` is the default. Included for ease of memory. Uses Benjamini-Hochberg adjustment of p-values. Minimum cutoff to call significant regions.  
   1. `--gsize hs` is for mappable genome size of humans. Set to 'mm' for mouse.  
1. 50_sbatchCallPeaks.sh will also create a "bed" version that prepends "chr" to the chromosome column and removes non-standard chromosomes.

   ```
   ### Create todo files
   ~$ ls -v $sdata/data/40_remDup | grep -v Input > $sdata/todo/50_callPeaks.txt
   ~$ ls -v $sdata/data/40_remDup | grep Input > $sdata/todo/50_ctl.txt
   ### Run
   ~$ sbatch $sdata/code/sbatch/50_sbatchCallPeaks.sh
   ~$ mv $sdata/code/sbatch/callPeaks_* $sdata/logs/50_callPeaks
   ```

1. Count peaks to check all quality of samples.

   ```
   ~$ sh $sdata/code/qc/30_countPeaks.sh $sdata/data/50_peaks $sdata/data/qc/summary
   ```

1. Run MACS2 again, this time with `bdgcmp` instead of `callpeak`
   1. `macs2 bdgcmp` will 'deduct noise by comparing two signal tracks in bedGraph'

   ```
   ~$ sbatch $sdata/code/sbatch/51_callPeaksBDGCMP.sh`
   ~$ mv $sdata/code/sbatch/callPeaks_BDGCMP_* $sdata/logs/51_callPeaksBDGCMP
   ```

1. Convert bedGraph files to bigWig files  
   1. A few extra scripts are required (located in `public/`). See above link for more detailed instruction.

   ```
   ~$ sbatch $sdata/code/sbatch/52_sbatchBdg2bw.sh
   ~$ mv $sdata/code/sbatch/bdg2bw_* $sdata/logs/52_bdg2bw
   ```
1. Run correlation on bigWig files to determine if replicates are good enough to combine.  
   1. Copy `$sdata/todo/50_callPeaks.txt` to `$sdata/todo/53_wigCorrelate.txt`
   1. Reformat so that all of the samples for each treatment are on a single line, with each file separated by a space.
   1. Additionally, must change suffix to be Fold Enrichment bigWig file
   1. Example:

   ```
   ~$ cat $sdata/todo/50_callPeaks.txt
   DNA180319MS_CM_IP_1_S28.bam
   DNA180319MS_CM_IP_2_S29.bam
   DNA180319MS_CM_IP_3_S30.bam 
   ~$ cat $sdata/todo/53_wigCorrelate.txt
   DNA180319MS_CM_IP_1_S28_FE.bw DNA180319MS_CM_IP_2_S29_FE.bw DNA180319MS_CM_IP_3_S30_FE.bw
   ```
   1. Run:  

   ```
   ~$ sbatch $sdata/code/sbatch/53_sbatchWigCorrelate.sh
   ~$ mv $sdata/code/sbatch/wigCorrelate_* $sdata/logs/53_wigCorrelate
   ```

1. Check the output files and create signal tracks if appropriate.
   1. Copy `$sdata/todo/53_wigCorrelate.txt` to `$sdata/todo/54_signalTrack.txt`
   1. Change suffix back to original bam file rather than _FE.bw

   ```
   ~$ sbatch $sdata/code/sbatch/54_sbatchSignalTracks.sh
   ~$ mv $sdata/code/sbatch/signalTrack_* $sdata/logs/54_signalTrack
   ```
   
   1. If you make signalTracks, you can also make the bedGraph and bigWig files. Use `55_sbatchSignalTrackBDGCMP.sh` the same way as `51_sbatchCallPeaksBDGCMP.sh` and use `56_sbatchSignalTrackBdg2bw.sh` the same way as `52_sbatchBdg2bw.`  
   1. Note that you will have to make a new todo file. It should contain the "basenames" of each signalTrack.

1. Run idr on samples as well.
   1. Copy `sdata/todo/54_signalTrack.txt` to `sdata/todo/60_idr.txt`
   1. Change suffixes to `_peaks.narrowPeak` rather than `.bam`

   ```
   ~$ sbatch $sdata/code/sbatch/60_sbatchIDR.sh
   ~$ mv $sdata/code/sbatch/idr_* $sdata/logs/60_idr
   ```

   1. Check the `.err` files to see IDR results.

REVIEW OF CURRENT DATA
======================

A lot of different files have been produced. Now to review what everything is and what its potential purpose is.  

### 50_peaks  

This directory contains the original output of the MACS2 peak calling step. There are a few different file formats that contain essentially the same information, along with some QC information. Data in this directory can be used to visualize peaks in a genome browser, but if you ran the signal track steps above, those results are better to use for that purpose.  

1. [sample]_control_lambda.bdg
   1. bedGraph of control peak windows for determining lambda
      1. Chromosome name
      1. Start of window
      1. End of window
      1. Maximum local lambda. Estimated using
         1. extsize
         1. slocal
         1. llocal
   1. lambda is expected number of reads in window, so the "control lambda" is basically the expected noise
   1. View this file along with the [sample]_treat_pileup.bdg to compare the treated peaks against the control noise.
1. [sample]_model.r
   1. Run this script to produce 'model shift size' and 'cross correlation' plots based on MACS2 run
   1. Generates files:
      1. [sample]_peakModel.pdf (model shift size)
      1. [sample]_crossCor.pdf (cross correlation)
1. [sample]_peaks.narrowPeak
   1. BED6+4 with peak locations and summit
      1. Chromosome name
      1. Start position of peak (0-based)
      1. End position of peak
      1. Peak name
      1. Integer score `int(-10*log10(qvalue))`
      1. Strand (I think)
      1. Fold enrichment for peak summit
      1. -log10(pvalue) for peak summit
      1. -log10(qvalue) for peak summit
      1. Relative summit position to peak start
   1. Able to load directly to UCSC genome browser
1. [sample]_peaks.xls
   1. Contains information about called peaks. One line per peak, plus header lines
      1. Chromosome name
      1. Start position of peak (1-based)
      1. End position of peak
      1. Length of peak region
      1. Absolute peak summit position
      1. pileup height at peak summit
      1. -log10(pvalue) for the peak summit
      1. Fold enrichment for the peak summit
         1. Enrichment is compared against random Poisson distribtuion with local lambda
      1. -log10(qvalue) of peak summit
      1. name of peak
   1. **NOTE THAT XLS COORDINATES ARE 1-BASED, WHICH IS DIFFERENT THAN BED'S O-BASED**
1. [sample]_summits.bed
   1. BED file with peak summit location for each peak
      1. Chromosome name
      1. Start position of summit (0-based). Will be `(narrowPeak start) + (narrowPeak relative summit position)`
      1. End position of summit. Will be one more than start position.
      1. Peak name
      1. -log10(qvalue) of peak summit 
1. [sample]_treat_pileup.bdg
   1. bedGraph file of treatment peak windows
      1. Chromosome name
      1. Start of window
      1. End of window
      1. Pileup score
      1. Scaled up or down relative to the control sample
      1. View this in IGV or UCSC browser and compare with the control sample

### 50.5_bedPeaks

This directory contains the exact same information as can be found in the [sample]_peaks.narrowPeak files in 50_peaks. The only difference is that the 1st column now has "chr" prepended to the chromosome number, which is required for some downstream tools.  

### 51_bdgcmp / 52_bw 

The bdgcmp subcommand is designed to generate noise-subtracted tracks. The MACS2 developer explains a little about it [here](https://groups.google.com/forum/#!topic/macs-announcement/yefHwueKbiY). These files are also good to view in a genome browser. The 52_bw directory contains the same information as that in 51_bdgcmp, except in the smaller bigWig binary format instead. It's recommended to use these files for viewing, since they are the easiest to transfer from exacloud.

1. [sample]_FE.bdg
   1. linear Fold Enrichment
   1. Simple descriptive measurement of difference between ChIP and control
   1. Can introduce high variability at low signals
1. [sample]_logLR.bdg
   1. log10 likelihood ratio between ChIP and control.
   1. Based on dynamic poisson model
   1. statistical evaluation of enrichment.

### 53_wigCorrelate  

There is nothing to use in this directory as far as downstream application. Each output file lists the input files used for the correlation as well as the corrletion score. You will have already looked at these scores to determine whether or not to proceed with the signal track construction.  

### 54_signalTrack / 55_st_bdgcmp / 56_st_bw  

This directory contains the exact same file types as described in 50_peaks, 51_bdgcmp, and 52_bw. There is now one file for each treatment/group and all replicates have been combined into that file. These peaks are much higher confidence than those in the individual files. Use these results for visualization.  

### 60_idr

IDR (Irreproducible Discovery Rate) is used to measure the reproducibility of results from replicate experiments, described [here](https://github.com/nboley/idr) in detail. If the `--plot` option is selected, a few QC plots will be created in addition to the consensus peak files.  

1. [sample]_idr
   1. modified BED file (20 total columns)
      1. Chromosome name
      1. Start position of peak (0-based)
      1. End position of peak
      1. Name given to a region. '.' is used if nothing assigned. (my results have '.')
      1. Scaled IDR value: `min(int(log2(-125*IDR)), 1000)`
         1. IDR of 0 corresponds to score of 1000
         1. IDR of 0.05 corresponds to 540
         1. IDR of 1 corresponds to 0
      1. strand (+, -, .)
      1. signal value. Measurement of enrichment for the region for merged peaks
      1. Merged peak p-value
      1. Merged peak q-value
      1. Merged peak summit
      1. local IDR Value: -log10(localIDR)
      1. global IDR Value: -log10(globalIDR)
      1. rep1 start position of peak. Shifted based on offset
      1. rep1 end position of peak
      1. rep1 signal measure
         1. If `--rank` option is set to `signal.value`, then this value will be the same as col7 of rep1's narrowPeak file
         1. If `--rank` option is set to `p.value`, then it will be the same as col8 of rep1's narrowPeak file
      1. rep1 summit value
      1. rep2 start, end, signal, summit
      1. repN start, end, signal, summit
1. [sample]_idr.png
   1. 4 different plots, see link above for full description.  

###
### Stop here 6/28/18
###

ANALYSIS
========


