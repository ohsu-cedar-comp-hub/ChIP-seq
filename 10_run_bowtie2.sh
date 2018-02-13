#!/bin/sh

###
### Run Bowtie2 for Alignment to sgRNA Reference
###

# Executable
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2

# Arguments
IN=$1
OUT=$2

# File manipulation
DIR=${IN%/*}
FILE=${IN##*/}
BASE=${FILE%%.*}

# Test
echo "IN: " $IN
echo "OUT: " $OUT
echo "DIR: " $DIR
echo "FILE: " $FILE
echo "BASE: " $BASE


## Arguments
#var=$1
#echo $var
#eval `echo $var | sed -e 's/^\([^:]\{1,\}\)\:\([^:]\{1,\}\)\:\([^:]\{1,\}\)\:\([^:]\{1,\}\)\:\([^:]\{1,\}\)\:\([^:]\{1,\}\)$/n=\1 u=\2 mydir=\3 fil=\4 in=\5 out=\6/'`
#
## Get arguments from to do file
#myfile="$mydir/$fil"
#mynum=`expr $n + 1`
#FULLFILE=`head -$mynum $myfile | tail -1`
#FILE="${FULLFILE%%.*}"
#
#
## Combine arguments
#IN=$mydir/data/$in
#OUT=$mydir/data/$out


# Run bowtie
cd $DIR
$BOWTIE -p 4 -3 81 -x library_ref -U $IN -S $OUT/$BASE.sam
