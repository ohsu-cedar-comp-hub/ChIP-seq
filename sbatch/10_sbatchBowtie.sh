#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                   # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             bowtie2_%A_%a.out       # Standard output
#SBATCH --error              bowtie2_%A_%a.err       # Standard error
#SBATCH --array              1-1                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/01_trim                               # Directory containing all input files. Should be one job per file
OUT=$sdata/data/10_sam                               # Directory where output files should be written
MYBIN=$sdata/code/10_run_bowtie2.sh                  # Path to shell script or command-line executable that will be used
REF=Homo_sapiens.GRCh38.87                           # Base name of the reference index files to use

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file
CURRFILE=`ls $IN/*.fq* | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'`

### Execute
mkdir -p $OUT

$MYBIN $CURRFILE $REF $OUT
