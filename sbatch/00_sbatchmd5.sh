#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
##SBATCH --mem-per-cpu       8000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --mem                16000                   # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             md5_%j.out              # Standard output
#SBATCH --error              md5_%j.err              # Standard error


### SET I/O VARIABLES

IN=$sdata/data/00_fastqs/                            # Directory containing all input files. Should be one job per file
MYBIN=$sdata/code/00_process.md5.R                   # Path to shell script or command-line executable that will be used

echo $IN
echo $sdata
echo $data

### Record slurm info

date
echo "SLURM_JOBID: " $SLURM_JOBID
printf "\n\n"

cmd="/usr/bin/Rscript $MYBIN $IN" 

echo $cmd
eval $cmd

