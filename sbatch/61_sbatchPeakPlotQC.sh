#!/bin/bash

### For each sample, run the model.r script and also split the resulting pdf into two separate files.

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             2                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        12000                   # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem               16000                   # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             peakPlot_%j.out         # Standard output
#SBATCH --error              peakPlot_%j.err         # Standard error

### SET I/O VARIABLES

IN=$sdata/data/50_peaks                              # Directory containing all input files. Should be one job per file
OUT=$sdata/data/50_peaks			     # Path to output directory

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Function
function pdfsplit ()
{
    if [ $# -lt 4 ]; then
        echo "Usage: pdfsplit input.pdf first_page last_page output.pdf"
        echo "Function Taken from Westley Weimer - www.cs.virginia.edu/~weimer/pdfsplit/pdfsplit"
#       exit 1
    fi

    yes | gs -dBATCH -sOutputFile="$4" -dFirstPage=$2 -dLastPage=$3 -sDEVICE=pdfwrite "$1" >& /dev/null
}


cd $IN

for file in `ls $IN/*.r`; do
	## Get base
	BASE=${file%_model.r}
	BASE=`basename $BASE`
	## Create pdf
	/usr/bin/Rscript $file
	## Split pdf
	pdfsplit $IN/$BASE\_model.pdf 1 1 $IN/$BASE\_peakModel.pdf
	pdfsplit $IN/$BASE\_model.pdf 2 2 $IN/$BASE\_crossCor.pdf
	## Remove original
	rm $IN/$BASE\_model.pdf
done
