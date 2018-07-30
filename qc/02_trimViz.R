###
### Trimmomatic QC Visualization
###

### After processing the trimmomatic output files, we have two files per sample.
### Summary File - shows total number of reads, how many were trimmed, etc.
### trimDist File - has distribution of length of trims

### Read both files in and display summary visualizations for them.
  ### Summary - scatterplot of % trimmed for reads and bases
  ### trimDist - histogram of trim lengths

### TODO - not entirely generalized.

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

suppressMessages(library(data.table))
suppressMessages(library(ggplot2))
suppressMessages(library(ggpubr))
suppressMessages(library(optparse))
suppressMessages(library(here))
myDir_v <- Sys.getenv("sdata")
source(file.path(myDir_v, "code/qc/helperFxns.R"))

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
  make_option(
    c("-s", "--summaryDir"),
    type = "character",
    help = "Path to directory of processed trimLog files. Usually $sdata/data/qc/trimLogProcessed/summary/"
  ),
  make_option(
    c("-t", "--trimDistDir"),
    type = "character",
    help = "Path to directory of processed trim distribution files. Usually $sdata/data/qc/trimLogProcessed/trimDist/"
  ),
  make_option(
    c("-m", "--meta"),
    type = "character",
    help = "Path to metadata file describing treatments, sample ID, etc. Required columns:
    'Sample.Name' 'Sample.Num' 'Treat' 'Replicate' 'Type'"
  ),
  make_option(
    c("-o", "--outDir"),
    type = "character",
    help = "Output directory for QC plots. Usually $sdata/data/qc/trimLogProcessed/plots."
  )
)

p <- OptionParser(usage = "%prog -s summaryDir -t trimDistDir -m meta -o outDir",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

summaryDir_v <- args$summaryDir
trimDistDir_v <- args$trimDistDir
meta_v <- args$meta
outDir_v <- args$outDir

##############
### INPUTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##############

###
### SUMMARY DATA
###

summaryFiles_v <- list.files(summaryDir_v)
summaryData_lsdt <- sapply(summaryFiles_v, function(x) {
  y <- fread(file.path(summaryDir_v, x), header = F)
  y$V2 <- as.numeric(gsub(',| ', '', y$V2))
  colnames(y) <- c("Group", "Count")
  return(y)}, simplify = F)
names(summaryData_lsdt) <- gsub(".*_S", "S", gsub("_summary.txt", "", summaryFiles_v))

###
### TRIM DISTR DATA
###

trimFiles_v <- list.files(trimDistDir_v)
trimData_lsdt <- sapply(trimFiles_v, function(x) fread(file.path(trimDistDir_v, x)), simplify = F)
names(trimData_lsdt) <- gsub(".*_S", "S", gsub("_trimDist.txt", "", trimFiles_v))

###
### METADATA
###

meta_dt <- fread(meta_v)

###################
###################
##### SUMMARY #####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################
###################

###############
### WRANGLE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### COMBINE SUMMARY FILES
summaryData_lsdt <- sapply(names(summaryData_lsdt), function(x) {
  y <- as.data.table(t(summaryData_lsdt[[x]]))
  colnames(y) <- unlist(y[1,]); y <- y[-1,]
  y$Sample <- x
  y <- y[,c(ncol(y),1:(ncol(y)-1)),with=F]
  return(y)
}, simplify = F)

summaryData_dt <- do.call(rbind, summaryData_lsdt)
for (col_v in grep("Sample", colnames(summaryData_dt), value = t, invert = T)) set(summaryData_dt, j = col_v, value = as.numeric(summaryData_dt[[col_v]]))

### GET PERCENTAGES
summaryData_dt$adapterReadPct <- round(summaryData_dt$Reads_with_adapters / summaryData_dt$Total_reads_processed * 100, digits = 2)
summaryData_dt$adapterTrimPct <- round(summaryData_dt$`Quality-trimmed` / summaryData_dt$Total_basepairs_processed * 100, digits = 2)

### DIVIDE READS BY 1 MILLION
summaryData_dt$Total_reads_processed <- summaryData_dt$Total_reads_processed / 1000000

### ADD METADATA
summaryData_dt <- merge(summaryData_dt[,mget(c("Sample", "Total_reads_processed", "adapterReadPct", "adapterTrimPct"))],
                        meta_dt[,mget(c("Sample.Num", "Treat", "Type", "Replicate"))], by.x = "Sample", by.y = "Sample.Num", sort = F)

### MELT
summaryMelt_dt <- melt(summaryData_dt, measure.vars = c("Total_reads_processed", "adapterReadPct", "adapterTrimPct"))

### Fix replicate
summaryMelt_dt$Replicate <- factor(summaryMelt_dt$Replicate)

############
### PLOT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

totalReads <- ggplot(aes(x = Treat, y = value, color = Treat, shape = Replicate), data = summaryMelt_dt[variable == "Total_reads_processed",]) +
  geom_point(size = 4) + big_label + angle_x +
  ggtitle("Total Reads") + 
  theme(axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(color = "Treatment", y = "Reads (millions)")

pctTrimRead <- ggplot(aes(x = Treat, y = value, color = Treat, shape = Replicate), data = summaryMelt_dt[variable == "adapterReadPct",]) +
  geom_point(size = 4) + big_label + angle_x +
  ggtitle("Percent of Reads Trimmed") + 
  theme(axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(color = "Treatment", y = "Percent")

pctTrimBase <- ggplot(aes(x = Treat, y = value, color = Treat, shape = Replicate), data = summaryMelt_dt[variable == "adapterTrimPct",]) +
  geom_point(size = 4) + big_label + angle_x +
  ggtitle("Percent of Bases Trimmed") + 
  theme(axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(color = "Treatment", y = "Percent")

finalPlot <- ggarrange(totalReads, pctTrimRead, pctTrimBase, nrow = 1, ncol = 3, common.legend = T, legend = "bottom")

finalFigure <- annotate_figure(finalPlot,
                               top = text_grob("Trim Results", size = 20))

pdf(file = file.path(outDir_v, "trimSummary.pdf"), width = 10)

print(finalFigure)

dev.off()

#####################
#####################
##### TRIM DIST #####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#####################
#####################

###############
### WRANGLE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### Treatments
treats_v <- unique(meta_dt$Treat)

### List
comboTrimData_lsdt <- list()

for (i in 1:length(treats_v)){
  ## Get treat and samples
  currTreat_v <- treats_v[i]
  currSamples_v <- meta_dt[Treat == currTreat_v, Sample.Num]
  ## Add sample column to each
  currData_lsdt <- sapply(currSamples_v, function(x){
    y <- trimData_lsdt[[x]]
    y$Sample <- x
    y$Type <- meta_dt[Sample.Num == x, Type]
    y$count <- y$count /1000000
    return(y)
  }, simplify = F)
  ## Combine
  currData_dt <- do.call(rbind,currData_lsdt)
  ## Add to list
  comboTrimData_lsdt[[currTreat_v]] <- currData_dt
}


############
### PLOT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

pdf(file = file.path(outDir_v, "trimLengthDistributions.pdf"))

for (i in 1:length(comboTrimData_lsdt)){
	## Get name and data
	currName_v <- names(comboTrimData_lsdt)[i]
	currData_dt <- comboTrimData_lsdt[[currName_v]]
	## Make Plot
	currPlot_gg <- ggplot(currData_dt, aes(x = length, y = count, fill = Type)) +
		geom_bar(stat="identity") + facet_wrap(~ Sample) +
		labs(x = "Trimmed Length", y = "Count (millions)") +
		my_theme + ggtitle(paste0("Histogram of Trimmed Lengths - ", currName_v))
	## Print plot
	print(currPlot_gg)
} # for i
dev.off()
