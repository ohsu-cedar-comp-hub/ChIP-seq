#!/bin/sh

###
### QC for bowtie2 alignment output
###

### Notes/Comments
	### Bowtie2 only outputs one alignment per read by default. Can use '-k N' to search for and output up to N multiple alignments
	### Bowtie2 uses the XS:i:# flag to output the alignment score for the next-best alignment.
	### This script has more steps than absolutely necessary. I keep track of multi and uniq alignments just in case I come up
	### with an informative way to plot the distribution of quality reads from these subsets. 
	### Could re-work this so that I don't split by unique/multi and only split on mapq. Would save some time, end result is
	### the same, but less information to run QC on.

### Procedures in this Script
	### 1. Split single and multi-mappers.
	###	Use the XS flag to split between single and multi-map reads. output into two separate files.
	### 2. Split into 'good' and 'bad' reads
	###	Use a MAPQ score cut-off (I use 10)
	### 3. Combine good/bad reads from the multi and unique divisions into final files
	### 4. Double check file-sizes (this takes a while to run)
	### 5. Sort by coordinate
	### 6. Get mapQ Score Distribution
	###	Want to record the distributions of both single- and multi-map reads.

# Executables
BOWTIE=/home/exacloud/lustre1/BioCoders/Applications/anaconda2/bin/bowtie2
SAMTOOLS=/home/exacloud/lustre1/BioCoders/Applications/samtools-1.3.1/bin/samtools

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

echoerr() { printf "%s\n" "$*" >&2; }

####################
### 0. SELECTION ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Mark which sections need to be run
SPLIT1=false
SPLIT2=false
COMBO=false
CHECK=false
SORT=true
MAPQ=false


############################################
### 1. SPLIT - UNIQ VS MULTI VS UNMAPPED ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############################################

### Split bam output files into unmapped, single- and multi-mappers. Multi-mappers contain the "XS:i:" string

if $SPLIT1; then

	### Prep
	cd $DIR
	mkdir -p $OUT/30_uniq_map $OUT/31_multi_map $OUT/32_unmapped_ids

	### Update user
	echoerr Split unmapped, single- and multi-mappers
	echoerr ''

	### Create files with headers
	echoerr Create headers
	$SAMTOOLS view -H $IN > $OUT/30_uniq_map/$BASE.sam
	cp $OUT/30_uniq_map/$BASE.sam $OUT/31_multi_map/$BASE.sam

	### Filter and add to headers
	### The `-f` option will output all alignments WITH that flag set, wherease the `-F` option will output all alignments WITHOUT that flag
	### So `-f 4` will get all unmapped reads (i.e. have flag 4 set) and `-F 4` will get all mapped reads. 
	echoerr Filter unique reads
	$SAMTOOLS view -F 4 $IN | grep -v "XS:i:" >> $OUT/30_uniq_map/$BASE.sam

	echoerr Filter multi-map reads
	$SAMTOOLS view -F 4 $IN | grep "XS:i:" >> $OUT/31_multi_map/$BASE.sam

	echoerr Extract unmapped IDs
	$SAMTOOLS view -f 4 $IN | cut -f 1 > $OUT/32_unmapped_ids/$BASE\_ids.txt

	### Convert back to bam
	echoerr Convert unique
	$SAMTOOLS view -bS $OUT/30_uniq_map/$BASE.sam > $OUT/30_uniq_map/$BASE.bam

	echoerr Convert multi-map
	$SAMTOOLS view -bS $OUT/31_multi_map/$BASE.sam > $OUT/31_multi_map/$BASE.bam

	### Remove sam
	rm $OUT/30_uniq_map/$BASE.sam
	rm $OUT/31_multi_map/$BASE.sam

fi

###################################
### 2. SPLIT - GOOD VS BAD MAPQ ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################################

### Further divide the unique reads into quality mapq scores and not quality.
### Quality from unique and multi-mapped will be combined together.

if $SPLIT2; then

	### Prep
	mkdir -p $OUT/30_uniq_map/good $OUT/30_uniq_map/bad $OUT/31_multi_map/good $OUT/31_multi_map/bad


	### First get the good ones (easier)
	echoerr Filter good reads
	$SAMTOOLS view -bq 10 $OUT/30_uniq_map/$BASE.bam > $OUT/30_uniq_map/good/$BASE.bam
	$SAMTOOLS view -bq 10 $OUT/31_multi_map/$BASE.bam > $OUT/31_multi_map/good/$BASE.bam

	### Now get the bad ones
	echoerr Filter bad reads

	### Unique reads
	$SAMTOOLS view -H $OUT/30_uniq_map/$BASE.bam > $OUT/30_uniq_map/bad/$BASE.sam
	$SAMTOOLS view $OUT/30_uniq_map/$BASE.bam | awk -F '\t' '{if ($5 <= 10) print $0}' >> $OUT/30_uniq_map/bad/$BASE.sam
	$SAMTOOLS view -bS $OUT/30_uniq_map/bad/$BASE.sam > $OUT/30_uniq_map/bad/$BASE.bam
	rm $OUT/30_uniq_map/bad/$BASE.sam

	### Multi reads
	$SAMTOOLS view -H $OUT/31_multi_map/$BASE.bam > $OUT/31_multi_map/bad/$BASE.sam
	$SAMTOOLS view $OUT/31_multi_map/$BASE.bam | awk -F '\t' '{if ($5 <= 10) print $0}' >> $OUT/31_multi_map/bad/$BASE.sam
	$SAMTOOLS view -bS $OUT/31_multi_map/bad/$BASE.sam > $OUT/31_multi_map/bad/$BASE.bam
	rm $OUT/31_multi_map/bad/$BASE.sam

fi

#################################
### 3. COMBINE - UNIQ + MULTI ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#################################

### Now we want to combine the unique and multi reads into good and bad

if $COMBO; then

	### Prep
	mkdir -p $OUT/33_good_reads $OUT/34_bad_reads

	### Good reads
	echoerr Combine good reads
	$SAMTOOLS view -H $OUT/30_uniq_map/$BASE.bam > $OUT/33_good_reads/$BASE.sam
	$SAMTOOLS view $OUT/30_uniq_map/good/$BASE.bam >> $OUT/33_good_reads/$BASE.sam
	$SAMTOOLS view $OUT/31_multi_map/good/$BASE.bam >> $OUT/33_good_reads/$BASE.sam
	$SAMTOOLS view -bS $OUT/33_good_reads/$BASE.sam > $OUT/33_good_reads/$BASE.bam
	rm $OUT/33_good_reads/$BASE.sam

	### Bad reads
	echoerr Combine bad reads
	$SAMTOOLS view -H $OUT/30_uniq_map/$BASE.bam > $OUT/34_bad_reads/$BASE.sam
	$SAMTOOLS view $OUT/30_uniq_map/bad/$BASE.bam >> $OUT/34_bad_reads/$BASE.sam
	$SAMTOOLS view $OUT/31_multi_map/bad/$BASE.bam >> $OUT/34_bad_reads/$BASE.sam
	$SAMTOOLS view -bS $OUT/34_bad_reads/$BASE.sam > $OUT/34_bad_reads/$BASE.bam
	rm $OUT/34_bad_reads/$BASE.sam

fi

################
### 4. CHECK ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
################

### The good/ and bad/ files should equal the parent file.
### uniq and multi good should equal final (same for bad)

if $CHECK; then

	echoerr Getting file sizes to compare

	### Parent size
	uniqN=`$SAMTOOLS view $OUT/30_uniq_map/$BASE.bam | wc -l`
	multiN=`$SAMTOOLS view $OUT/31_multi_map/$BASE.bam | wc -l`

	### Good/bad size
	uniqGoodN=`$SAMTOOLS view $OUT/30_uniq_map/good/$BASE.bam | wc -l`
	uniqBadN=`$SAMTOOLS view $OUT/30_uniq_map/bad/$BASE.bam | wc -l`
	uniqGoodBadSum=$((uniqGoodN + uniqBadN))

	multiGoodN=`$SAMTOOLS view $OUT/31_multi_map/good/$BASE.bam | wc -l`
	multiBadN=`$SAMTOOLS view $OUT/31_multi_map/bad/$BASE.bam | wc -l`
	multiGoodBadSum=$((multiGoodN + multiBadN))

	uniqMultiGoodSum=$((uniqGoodN + multiGoodN))
	uniqMultiBadSum=$((uniqBadN + multiBadN))

	### Final good and bad
	comboGoodN=`$SAMTOOLS view $OUT/33_good_reads/$BASE.bam | wc -l`
	comboBadN=`$SAMTOOLS view $OUT/34_bad_reads/$BASE.bam | wc -l`

	### Compare parent with good/bad
	if [[ $uniqGoodBadSum != $uniqN ]]; then echo ERROR: Unique good/bad division does not equal unique input; exit 1; fi
	if [[ $multiGoodBadSum != $multiN ]]; then echo ERROR: Multi good/bad division does not equal multi input; exit 1; fi

	### Compare final with good/bad
	if [[ $uniqMultiGoodSum != $comboGoodN ]]; then echo ERROR: Unique good + Multi good division does not equal total good output; exit 1; fi
	if [[ $uniqMultiBadSum != $comboBadN ]]; then echo ERROR: Unique bad + Multi bad division does not equal total bad output; exit 1; fi

fi

###############
### 5. SORT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### After combining everything together, have to re-sort so that markdups will work

if $SORT; then

	echoerr Re-sorting files
	$SAMTOOLS sort -o $OUT/33_good_reads/$BASE\_sort.bam $OUT/33_good_reads/$BASE.bam
	$SAMTOOLS sort -o $OUT/34_bad_reads/$BASE\_sort.bam $OUT/34_bad_reads/$BASE.bam

	mv $OUT/33_good_reads/$BASE\_sort.bam $OUT/33_good_reads/$BASE.bam
	mv $OUT/34_bad_reads/$BASE\_sort.bam $OUT/34_bad_reads/$BASE.bam

fi

###############
### 6. MAPQ ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### Print the 5th column of each sam record, which is the MapQ Score.

if $MAPQ; then

	### Prep
	mkdir -p $OUT/qc/uniq_mapq $OUT/qc/multi_mapq

	### Update user
	echoerr ''
	echoerr ''
	echoerr Mapq Filter QC

	### Make new variables
	UNIQ=$OUT/30_uniq_map/$BASE.bam
	MULTI=$OUT/31_multi_map/$BASE.bam

	### Extract score
	$SAMTOOLS view $UNIQ | awk -F '\t' '{print $5}' | sort | uniq -c | sed 's/^ *//' | tr ' ' '\t' | sort -n -k 2 > $OUT/qc/uniq_mapq/$BASE.txt
	$SAMTOOLS view $MULTI | awk -F '\t' '{print $5}' | sort | uniq -c | sed 's/^ *//' | tr ' ' '\t' | sort -n -k 2 > $OUT/qc/multi_mapq/$BASE.txt

fi
