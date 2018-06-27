#!/bin/bash


#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        32000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             phantom_%A_%a.out        # Standard output
#SBATCH --error              phantom_%A_%a.err        # Standard error
#SBATCH --array              1-1                    # sets number of jobs in array

### SET I/O VARIABLES

IN=$sdata/data/40_remDup/
OUT=$sdata/data/70_phantom/
TODO=$sdata/todo/70_phantom
CTL=$sdata/todo/50_ctl.txt
MYBIN=$sdata/code/phantompeakqualtools/run_spp.R
FIELD=1    # (if input file name is split by "_", which field will have treatment? 0-based.

mkdir -p $OUT

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

### create array of file names in this location (input files)
### This only works if the output goes to a new location...if you're writing output to same directory use other method
CURRFILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Get treatment
IFS='_' read -ra FILEARRAY <<< "$CURRFILE"
TREAT=${FILEARRAY[$FIELD]}

### Get control file
CTLFILE=`grep "$TREAT" $CTL`

### Get base name
BASE=${CURRFILE%.bam}

### Print everything
printf "Input directory: %s\n" "$IN"
printf "Input file: %s\n" "$CURRFILE"
printf "Treatment: %s\n" "$TREAT"
printf "Control file: %s\n" "$CTLFILE"
printf "Out dir: %s\n\n\n" "$OUT"

### Execute

cmd="Rscript $MYBIN \
	-c=$IN/$CURRFILE \
	-i=$IN/$CTLFILE \
	-odir=$OUT \
	-savn=$BASE\.np \
	-savr=$BASE\.rp \
	-savd \
	-savp=$BASE\_crossCor \
	-out=$BASE\_phantomResults \
	-rf"

echo $cmd
eval $cmd
