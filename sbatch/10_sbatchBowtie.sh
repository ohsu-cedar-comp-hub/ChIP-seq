#!/bin/bash

### This script provides a template containg many of the commonly-used resource management SBATCH commands.
### You can submit this script as-is using `sbatch sbatchTemplate.sh` and it will output the slurm info into each log file.
### Use the following commands to combine the 10 (default) log files into a space-delimited file for testing purposes.
### From directory of output files (directory where sbatch is run from):

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             bowtie2_%A_%a.out        # Standard output
#SBATCH --error              bowtie2_%A_%a.err        # Standard error
#SBATCH --array              1-8                    # sets number of jobs in array

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

IN=$sdata/data/01_trim                       # Directory containing all input files. Should be one job per file
OUT=$sdata/data/10_sam                       # Directory where output files should be written
MYBIN=$sdata/code/10_run_bowtie2.sh          # Path to shell script or command-line executable that will be used
REF=Homo_sapiens.GRCh38.87                # Base name of the reference index files to use
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

CURRFILE=`ls $IN/*.fq* | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'`


### Execute
mkdir -p $OUT

$MYBIN $CURRFILE $REF $OUT


