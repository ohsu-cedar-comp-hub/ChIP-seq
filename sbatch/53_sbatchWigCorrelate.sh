#!/bin/bash

### This script provides a template containg many of the commonly-used resource management SBATCH commands.
### You can submit this script as-is using `sbatch sbatchTemplate.sh` and it will output the slurm info into each log file.
### Use the following commands to combine the 10 (default) log files into a space-delimited file for testing purposes.
### From directory of output files (directory where sbatch is run from):

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             2                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             wigCorrelate_%A_%a.out        # Standard output
#SBATCH --error              wigCorrelate_%A_%a.err        # Standard error
#SBATCH --array              1-2                    # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/52_bw                           # Directory containing all input files. Should be one job per file
OUT=$sdata/data/53_wigCorrelate/
MYBIN=$sdata/misc/wigCorrelate                    # Path to shell script or command-line executable that will be used
TODO=$sdata/todo/53_wigCorrelate.txt              # Todo file containing all files to call peaks for
TREAT=2                                           # Index of treatment in filename split by _

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
echo "SLURM_JOB_NODELIST: " $SLURM_JOB_NODELIST
echo "SLURM_CPUS_ON_NODE: " $SLURM_CPUS_ON_NODE
echo "SLURM_CPUS_PER_TASK: " $SLURM_CPUS_PER_TASK
echo "SLURM_JOB_CPUS_PER_NODE: " $SLURM_JOB_CPUS_PER_NODE
echo "SLURM_MEM_PER_CPU: " $SLURM_MEM_PER_CPU
echo "SLURM_MEM_PER_NODE: " $SLURM_MEM_PER_NODE
echo "SLURM_NTASKS: " $SLURM_NTASKS
echo "SLURM_NTASKS_PER_CORE " $SLURM_NTASKS_PER_CORE
echo "SLURM_NTASKS_PER_NODE " $SLURM_NTASKS_PER_NODE
echo "SLURM_TASKS_PER_NODE " $SLURM_TASKS_PER_NODE

### Get files (as an array)
CURRFILE=(`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`)

### Get length of array minus one
LEN=$(expr ${#CURRFILE[@]} - 1)

### Get treatment name for output
TREATNAME=`echo $CURRFILE | cut -d '_' -f $TREAT`

### Change suffix and add directory to each element of array
for i in $(eval echo "{0..$LEN}"); do
	temp=$IN/${CURRFILE[$i]}
	CURRFILE[$i]=$temp
done

### Double check
echo "Path and files that will be passed as input:"
echo ${CURRFILE[@]}
echo ''

### Execute
mkdir -p $OUT
cd $IN

cmd="$MYBIN ${CURRFILE[@]} > $OUT/$TREATNAME\_wigCorr.txt"

echo $cmd
eval $cmd
