#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                64000                   # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             bowtieBuild_%j.out      # Standard output
#SBATCH --error              bowtieBuild_%j.err      # Standard error

### SET I/O VARIABLES

### IN = PATH TO GENOME THAT WILL BE INDEXED FOR ALIGNMENT
### DIR = PATH TO INPUT DATA (FASTQ FILES THAT NEED TO BE ALIGNED)
### BASE = BASE NAME OF GENOME THAT WILL BE USED FOR INDEX OUTPUT FILES
### MYBIN = PATH TO SHELL SCRIPT/COMMAND-LINE EXECUTABLE THAT WILL BE USED

IN="$BIOCODERS/DataResources/Genomes/hg38/release-87/genome/Homo_sapiens.GRCh38.dna_sm.toplevel.fa"
DIR=$sdata/data/01_trim
BASE="Homo_sapiens.GRCh38.87"
MYBIN=$sdata/code/03_bowtieBuild.sh


### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Run
$MYBIN $DIR $IN $BASE
