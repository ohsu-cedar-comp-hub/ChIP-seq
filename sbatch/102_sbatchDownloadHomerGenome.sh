#!/bin/bash

### This script provides a template containg many of the commonly-used resource management SBATCH commands.
### You can submit this script as-is using `sbatch sbatchTemplate.sh` and it will output the slurm info into each log file.
### Use the following commands to combine the 10 (default) log files into a space-delimited file for testing purposes.
### From directory of output files (directory where sbatch is run from):

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
##SBATCH --mem-per-cpu        8000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --mem                64000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             genome_%j.out        # Standard output
#SBATCH --error              genome_%j.err        # Standard error

MYBIN=`perl $BIOCODERS/Applications/anaconda2/share/homer-4.9.1-5/configureHomer.pl -install human-p`

$MYBIN
