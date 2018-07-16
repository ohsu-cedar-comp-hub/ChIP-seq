#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             6                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        8000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             homer_%A_%a.out          # Standard output
#SBATCH --error              homer_%A_%a.err          # Standard error
#SBATCH --array              6-6                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/100_homer/input                             # Directory containing all input files. Should be one job per file
OUT=$sdata/data/100_homer/output                              # Directory where output files should be written
TODO=$sdata/todo/100_homer.txt
MYBIN=$sdata/code/100_runHomer.sh                      # Path to shell script or command-line executable that will be used

mkdir -p $OUT

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
echo ""

### Get a file using the task ID
CURRFILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Run trim bash script with input directory, input file and output directory
$MYBIN $IN/$CURRFILE $OUT

