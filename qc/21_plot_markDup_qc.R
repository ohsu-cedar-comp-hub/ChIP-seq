###
### Plot Mark Duplicate Results
###

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

library(data.table)
library(ggplot2)
suppressMessages(library(ggpubr))
library(gridExtra)
library(optparse)
myDir_v <- Sys.getenv("sdata")
source(file.path(myDir_v, "code/qc/helperFxns.R"))

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
    make_option(
        c("-i", "--inputFile"),
        type = "character",
        help = "Mapq summary file made by 51_bowtie_summary_stats.R. Usually $sdata/data/qc/summary/dupSummary.txt"
    ),
    make_option(
        c("-o", "--outDir"),
        type = "character",
        help = "Output directory for QC plots. Should be $sdata/data/qc/plots/alignQC."
    ),
    make_option(
      c("-t", "--treat"),
      type = "numeric",
      default = 1,
      help = "Element index to extract treatment from file identifier when identifier is split by '_'."
    ),
    make_option(
      c("-y", "--type"),
      type = "numeric",
      default = 2,
      help = "Element index to extract data type from file identifier when identifier is split by '_'."
    ),
    make_option(
      c("-r", "--rep"),
      type = "numeric",
      default = 3,
      help = "Element index to extract replicate from file identifier when identifier is split by '_'."
    )
)

p <- OptionParser(usage = "%prog -i inputFile -o outDir -t treat -y type -r rep",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

input_file_v <- args$inputFile
out_dir_v <- args$outDir
treat_v <- args$treat
type_v <- args$type
rep_v <- args$rep

####################
### SET UP INPUT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Get data
input_data_dt <- fread(input_file_v)

### Add treatment, type, and rep columns
input_data_dt$Treat <- sapply(input_data_dt$Sample, function(x) unlist(strsplit(x, split = "_"))[treat_v])
input_data_dt$Type <- sapply(input_data_dt$Sample, function(x) unlist(strsplit(x, split = "_"))[type_v])
input_data_dt$Rep <- sapply(input_data_dt$Sample, function(x) unlist(strsplit(x, split = "_"))[rep_v])

### Melt
melt_dt <- melt(input_data_dt[,mget(c("Sample", "PERCENT_DUPLICATION", "Treat", "Type", "Rep"))], measure.vars = "PERCENT_DUPLICATION")

### Multiply by 100
melt_dt$value <- melt_dt$value * 100

#############
### PLOTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

### Total reads
pctDup <- ggplot(aes(y = value, x = Treat, color = Treat, shape = Rep), data = melt_dt) +
  geom_point(size = 3) +
  ggtitle("Percent Duplication") +
  big_label + angle_x +
  labs(y = "Percent")

### Write
pdf(file = paste0(out_dir_v, "pctDuplication.pdf"), width = 10)

print(pctDup)

dev.off()

