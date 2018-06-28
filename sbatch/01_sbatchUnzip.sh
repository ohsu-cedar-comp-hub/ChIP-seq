#!/bin/bash

### Unzip all of the fastq files. 
### Need to first determine the number of different tens place file names there are. 
### There will be that many array jobs.

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                16000                   # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             unzip_%A_%a.out         # Standard output
#SBATCH --error              unzip_%A_%a.err         # Standard error
#SBATCH --array              0-14                    # sets number of jobs in array


### SET I/O VARIABLES

IN=$sdata/data/00_fastqs                             # Directory containing all input files. Should be one job per file
MYBIN=$stool/01_unzip.sh                             # Path to shell script or command-line executable that will be used
SMALL=true

### Record slurm info

date
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
printf "\n\n"

if $SMALL; then

	### Just do each file individually
	for file in `ls $IN`; do
		CMD="sh $MYBIN $IN $file"
		echo $CMD
		eval $CMD
	done
else
	### Split into multiple arrays.
        ### Will likely have to alter the file definition below
	### create array of file names in this location (input files)
	### Extract file name information as well
	
	### Get a template file
	TEMP=`ls -v $IN | head -1`
	BASE="${TEMP%%S[0-9]*}"
	TENS=$SLURM_ARRAY_TASK_ID
	
	### Print checks
	echo "Example file: " $TEMP
	echo "File base: " $BASE
	printf "\n\n"
	
	### Execute
	
	for i in {0..9}; do
	
	    ## Get file names
	    if [ $TENS == 0 ]; then
	        FILE1=$IN/$BASE\S$i\_R1_001.fastq.gz
	        FILE2=$IN/$BASE\S$i\_R2_001.fastq.gz
	    else
	        FILE1=$IN/$BASE\S$TENS$i\_R1_001.fastq.gz
	        FILE2=$IN/$BASE\S$TENS$i\_R2_001.fastq.gz
	    fi
	
	    ## Check file names
	    echo "Files to run: " $FILE1 $FILE2
	
	    ## Prepare command
	    cmd1="sh $MYBIN $FILE1"
	    cmd2="sh $MYBIN $FILE2"
	
	    ## Echo command
	    echo $cmd1
	    echo $cmd2
	
	    ## Evaluate command
	    eval $cmd1
	    eval $cmd2
	
	    printf "\n\n"
	
	done
