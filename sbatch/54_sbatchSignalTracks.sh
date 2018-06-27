#!/bin/bash

### This script provides a template containg many of the commonly-used resource management SBATCH commands.
### You can submit this script as-is using `sbatch sbatchTemplate.sh` and it will output the slurm info into each log file.
### Use the following commands to combine the 10 (default) log files into a space-delimited file for testing purposes.
### From directory of output files (directory where sbatch is run from):

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             6                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             signalTrack_%A_%a.out        # Standard output
#SBATCH --error              signalTrack_%A_%a.err        # Standard error
#SBATCH --array              1-1                    # sets number of jobs in array

: '
mv template_%A_10.out test1
for file in template_%A_[1-9].out; do
   cut -d ' ' -f 3 $file > temp; 
   paste -d ' ' test1 temp > test1a; 
   mv -f test1a test1; 
done; 
rm temp
'

### SET I/O VARIABLES

IN=$sdata/data/40_remDup                       # Directory containing all input files. Should be one job per file
OUT=$sdata/data/54_signalTrack                       # Directory where output files should be written
MYBIN=$sdata/code/54_signalTracks.sh              # Path to shell script or command-line executable that will be used
MACS2=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/macs2
TODO=$sdata/todo/54_signalTrack.txt              # Todo file containing all files to call peaks for
CTL=$sdata/todo/50_ctl.txt                     # File containing all controls
FIELD=1                                        # If input file name is split by "_", which field will have treatment? Remember this is 0-based

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

### Get file (as an array)
CURRFILE=(`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`)

### Get length of array minus one
LEN=$(expr ${#CURRFILE[@]} - 1)

### Get treatment
IFS='_' read -ra FILEARRAY <<< "$CURRFILE"
TREAT=${FILEARRAY[$FIELD]}

### Get control file
CTLFILE=`grep "$TREAT" $CTL`

### Add directory to data files
for i in $(eval echo "{0..$LEN}"); do
	temp=$IN/${CURRFILE[$i]}
	CURRFILE[$i]=$temp
done

### Execute
mkdir -p $OUT

cmd="
$MACS2 callpeak \
	--treatment ${CURRFILE[@]} \
	--control $IN/$CTLFILE \
	--name $TREAT \
	--outdir $OUT \
	--format BAM \
	-B \
	--SPMR \
	--qvalue 0.05 \
	--gsize hs \
	--verbose 4
"

echo $cmd
eval $cmd
