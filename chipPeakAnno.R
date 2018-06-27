###
### Run ChIP Peak Annotation Workflow
###

### Taken from: https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/pipeline.html
### ChIPpeakAnno 3.14.0

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

suppressMessages(library(ChIPpeakAnno))
suppressMessages(library(optparse))
suppressMessages(library(rtracklayer
#################
### ARGUMENTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#################

### Make list of options
optlist <- list(
	make_option(
		c("-i", "--inputFiles"),
		type = "character",
		help = "Paths to files containing identified peaks. Will usually be the output of MACS2.
			Individual files/paths are separated by a comma, with no spaces."),
	make_option(
		c("-o", "--outDir"),
		type = "character",
		help = "Path to where output files will be written"),
	make_option(
		c("-t", "--treatIndex"),
		type = "numeric",
		help = "Index of treatment identifier in file name, assuming name is separated by '_'."),
	make_option(
		c("-s", "--sampleIndex"),
		type = "numeric",
		help = "Index of sample identifier in file name, assuming name is separated by '_'."))

### Parse Command Line
p <- OptionParser(usage = "%prog -i inputBed -o outDir -t treatIndex -s sampleIndex"
args <- parse_args(p)
opt <- args$options

inputFiles_v <- args$inputFiles
outDir_v <- args$outDir
treat_v <- args$treatIndex
sample_v <- args$sampleIndex

###################
### PRE-PROCESS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################

inputData_lsbed <- sapply(inputBed_v, function(x) import(x, format = "bed"), simplify = F)

