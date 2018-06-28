#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             2                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                   # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             wigCorrelate_%A_%a.out  # Standard output
#SBATCH --error              wigCorrelate_%A_%a.err  # Standard error
#SBATCH --array              1-2                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/52_bw                                 # Directory containing all input files. Should be one job per file
OUT=$sdata/data/53_wigCorrelate/                     # Path to output directory
MYBIN=$sdata/misc/wigCorrelate                       # Path to shell script or command-line executable that will be used
TODO=$sdata/todo/53_wigCorrelate.txt                 # Todo file containing all files to call peaks for
TREAT=2                                              # Index of treatment in filename split by _

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

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
