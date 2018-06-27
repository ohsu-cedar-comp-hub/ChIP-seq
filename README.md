PROCEDURE FOR SHERMAN CRISPR SCREEN
===================================

Step-by-step instructions for how to analyze Sherman CRISPR data.  

SETUP
=====

1. Make sure that you have the following in your .bashrc, .bash_profile, or equivalent:  

   ```
   export sdata="/path/to/LIBXXXXXMS"
   export stool="/path/to/this/installation"
   ```

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
   ~$ MULTIQC=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/multiqc
   ~$ $MULTIQC $sdata/data/FastQC
   <copy files to local drive to view>
   ```

1. Unzip. (Not necessary, but useful to take a look at fastq files if you want).

   ```
   ~$ sbatch $sdata/code/sbatch/01_sbatchUnzip.sh
   ~$ mv $sdata/code/sbatch/unzip_* $sdata/logs/01_unzip
   ```

1. Trim adapter sequence and reformat log files

   ```
   ~$ sbatch $sdata/code/sbatch/02_sbatchTrimSeq.sh
   ~$ mv $sdata/data/01_trim/*_report.txt $sdata/data/02_trimLog
   ~$ cd $sdata/02_trimLog
   ~$ for file in *_report.txt; do name=${file%%_L005*}; sh $sdata/code/qc/01_processTrimLog.sh $file $name trimLogProcessed/; done
   ```

1. Create bowtie index.  

   ```
   ## Double check that $IN is the appropriate path
   ## Double check that $BASE is appropriate for your genome
   ~$ sbatch $sdata/code/sbatch/03_sbatchBowtieBuild.sh
   ```

PROCESS
=======

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

1. Mark duplicates with picard tools and reformat log files

   ```
   ~$ sbatch $sdata/code/sbatch/40_sbatchRemDup.sh
   ~$ mv $sdata/code/sbatch/remDup_* $sdata/logs/40_remDup
   ~$ sh $sdata/code/qc/02_processDupLog.sh $sdata/data/41_remDupLog $sdata/data/qc/summary
   ```

1. Aggregate bowtie QC stuff.

   ```
   ~$ Rscript $sdata/code/qc/bowtie_alignment_qc.R -i $sdata/logs/10_bowtie -f $sdata/data/10_sam -o $sdata/data/qc/summary
   ~$ for dir in `ls $sdata/data/qc/*_mapq`; do Rscript $sdata/code/bowtie_mapqDistr.R -i $sdata/data/qc/$dir -o $sdata/data/qc/summary -f "2,3,4,5"
   ``` 
   
1. Transfer data to local for R analysis.  

ANALYSIS
========

1. Trim QC
   1. Make trim directory and subdirectories: `mkdir -p trim trim/trimLog trim/trimLogOutput trim/trimLogProcessed`
   1. Place 02_trimLog files in trim/trimLog
   1. Process files. Copy usage command from `processTrimLog.sh` and run it
   1. Create visualizations using `trimViz.R`
 
1. Alignment QC
   1. Make viz directory (inside `alignmentQC` directory)
   1. Run alignment and count QC Scripts  

      1. 01_mapq_alignment_qc.R  
         1. Use the mapqc summary information to plot distributions of mapped, unmapped, and high-quality mapped reads.  
         1. 01_mapq_alignment_qc.R -i 50_qc/mapq_summary.txt -o ./plots/alignQC/  

      1. 02__plot_alignment_qc.R  
         1. Use the bowtie2 alignment QC summary file to plot percentages of mapped reads.  
         1. 02_plot_alignment_qc.R -i 50_qc/bowtie2.alignment.QC.summary.txt ./plots/alignQC -r 2,2,2  

1. FastQC QC
   1. Run multiqc if you didn't run it earlier on exacloud
   1. Review the multiqc results
   1. Run the over-represented sequence script `20_fastQCOverRepSeqs.sh`
