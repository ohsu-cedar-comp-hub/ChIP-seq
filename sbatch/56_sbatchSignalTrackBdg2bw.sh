#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             2                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                   # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem               16000                   # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             st_bdg2bw_%A_%a.out     # Standard output
#SBATCH --error              st_bdg2bw_%A_%a.err     # Standard error
#SBATCH --array              1-2                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/55_st_bdgcmp                           # Directory containing all input files. Should be one job per file
OUT=$sdata/data/56_st_bw                             # Directory where output files should be written
MYBIN=$sdata/code/52_bdg2bw.sh                       # Path to shell script or command-line executable that will be used
TODO=$sdata/todo/55_signalTrack_bdgcmp.txt           # Todo file containing all files to call peaks for

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file
CURRFILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Execute
mkdir -p $OUT

$MYBIN $IN/$CURRFILE $OUT
