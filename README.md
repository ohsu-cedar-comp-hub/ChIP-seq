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
   ~$ mv $sdata/code/sbatch/md5_* $sdata/code/logs/00_md5
   ```
   
1. Run multiqc on FastQC files.  

   ```
   ~$ multiqc $sdata/data/FastQC
   <copy files to local drive to view>
   ```

1. Unzip.  

   ```
   ~$ sbatch $sdata/code/sbatch/01_sbatchUnzip.sh
   ~$ mv $sdata/code/sbatch/unzip_* $sdata/code/logs/01_unzip
   ```

1. Create bowtie index.  

   ```
   ~$ BUILD=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2-build
   ~$ cd $sdata/data/00_fastqs
   ~$ $BUILD library_ref.fasta library_ref
   ```

PROCESS
=======

1. Run bowtie2.  

   ```
   ~$ sbatch $sdata/code/sbatch/10_sbatchBowtie.sh
   ~$ mv $sdata/code/sbatch/bowtie2_* $sdata/code/logs/10_bowtie
   ```

1. Convert sam files to bam.  

   ```
   ~$ sbatch $sdata/code/sbatch/20_sbatchSam2Bam.sh
   ~$ mv $sdata/code/sbatch/s2b_* $sdata/code/logs/20_s2b
   ```

1. Filter data and get some QC. info.  
   1. MapQ - print all of the mapQ scores from the bam files.  
   1. Multi-map  
      1. Filter out unique reads using mapQ score. Keep scores greater than 10.  
      1. Collect the multi-mappers to a separate directory.  
   1. Find un-mapped fastq entries.  


   ```
   ~$ sbatch $sdata/code/sbatch/30_sbatchFilterQC.sh
   ~$ mv $sdata/code/sbatch/filterQC_* $sdata/code/logs/30_filter_and_qc
   ```

1. Convert data for downstream analysis.  

   ```
   ~$ sbatch $sdata/code/sbatch/40_sbatchConvert.sh
   ~$ mv $sdata/code/sbatch/convert_* $sdata/code/logs/40_convert
   ```

1. Aggregate bowtie QC stuff.

   ```
   ~$ cp $sdata/code/logs/10_bowtie/*.err $sdata/code/logs/50_error
   ~$ Rscript $sdata/code/50_bowtie_alignment_qc.R -i $sdata/code/logs/50_error -f $sdata/data/10_sam -o $sdata/data/50_qc
   ~$ Rscript $sdata/code/51_bowtie_summary_stats.R -i $sdata/data/50_qc/mapqc -o $sdata/data/50_qc -l [T/F]
   ```
   
1. Transfer data to local for R analysis.  
   1. 40_convert  
   2. 41_carpools  
   3. 50_qc  

ANALYSIS
========