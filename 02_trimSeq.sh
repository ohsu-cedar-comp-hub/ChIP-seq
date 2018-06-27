#!/bin/sh

###
### Trim alignments with Trim Galore!
###

# Executable
TRIM=/home/exacloud/lustre1/BioCoders/Applications/trim_galore

# Arguments
IN=$1                  # Path to input directory
FILE=$2                # Full path to input file
OUT=$3                 # Path to output directory

# Print arguments
echo ""
echo "IN: " $IN
echo "FILE: " $FILE
echo "OUT: " $OUT
echo ""

# Run trim galore
cmd="$TRIM --output_dir $OUT $FILE"

echo $cmd
eval $cmd
