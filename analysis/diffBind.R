###
### Assess Differential Binding of ChIP-Seq Results
###

#####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Required Packages
suppressMessages(library(DiffBind))
suppressMessages(library(ChIPpeakAnno))
suppressMessages(library(GenomicRanges))
suppressMessages(library(xlsx))
suppressMessages(library(optparse))
library(data.table)

### Annotation Packages
source("https://bioconductor.org/biocLite.R")
#biocLite(c("EnsDb.Hsapiens.v86", "org.Hs.eg.db", "reactome.db", "BSgenome.Hsapiens.UCSC.hg38"))
library(EnsDb.Hsapiens.v86)
library(biomaRt)
library(org.Hs.eg.db)
library(reactome.db)
library(BSgenome.Hsapiens.UCSC.hg38)

### Source functions
myDir_v <- Sys.getenv("sdata")
source(file.path(myDir_v, "code/qc/helperFxns.R"))

#################
### ARGUMENTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#################

### Make list of options
optlist <- list(
  make_option(
    c("-b", "--baseDir"),
    type = "character",
    help = "Path to the base directory containing all of the files"
  ),
  make_option(
    c("-m", "--meta"),
    type = "character",
    help = "Path to metadata file containing sample names, treatment info, etc."
  ),
  make_option(
    c("-n", "--minOv"),
    type = "numeric",
    help = "Integer specifying the minimum number of samples a peak must be found in."
  ),
  make_option(
    c("-p", "--plot"),
    type = "logical",
    help = "TRUE - write plots to output; FALSE - do not write plots."
  ),
  make_option(
    c("-o", "--outDir"),
    type = "character",
    help = "Directory where output will be written. Not a full path, will be within baseDir"),
  make_option(
    c("-d", "--homerDir"),
    type = "character",
    help = "Optional. If specified, will write bed file to this directory for subsequent homer analysis. 
    If not specified, will write to normal output directory only."
  )
)

### Parse Command Line
p <- OptionParser(usage = "%prog -i baseDir -m meta -n minOv -p plot -o outDir -h homerDir",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

baseDir_v <- args$baseDir
meta_v <- args$meta
minOv_v <- args$minOv
plot_v <- args$plot
outDirName_v <- args$outDir
homerDir_v <- args$homerDir

### For testing
# baseDir_v <- "~/projs/Sherman/DNA180319MS/diffBind/"
# meta_v <- "~/projs/Sherman/DNA180319MS/meta/narrow_meta.csv"
# # homerDir_v <- "~/projs/Sherman/DNA180319MS/homer/input/"
# homerDir_v <- NULL
# outDirName_v <- "narrow"
# minOv_v <- 2
# plot_v <- F

###################
### PRE-PROCESS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################

### Make output directory
intDir_v <- mkdir(baseDir_v, "output")
intDir_v <- mkdir(intDir_v, outDirName_v)
outDir_v <- mkdir(intDir_v, paste0("minOv_", minOv_v))

### Make plotting directories
diffPlotDir_v <- mkdir(outDir_v, "diffBindPlots")
annotPlotDir_v <- mkdir(outDir_v, "annotationPlots")

### Read in sample sheet (metadata)
samples_df <- read.csv(meta_v)

### Read in peaks
data_dba <- dba(sampleSheet = samples_df, dir = baseDir_v, minOverlap = 1)

### Print
data_dba
dim(data_dba$merged)

### Correlation heatmap on peakcaller data (occupancy scores)
if (plot_v) pdf(file = file.path(diffPlotDir_v, "occupancyScore_CorrelationHeat.pdf"))
plot(data_dba)
if (plot_v) dev.off()

###################
### COUNT READS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################

### Assign value for summits
summits_v <- 250

### Count reads with summit centering
data_dba <- dba.count(data_dba, summits = summits_v, minOverlap = minOv_v)

### Display DBA object
data_dba
dim(data_dba$merged)

### Plot correlation heatmap on new count data (affinity scores)
if (plot_v) pdf(file = file.path(diffPlotDir_v, "affinityScore_CorrelationHeat.pdf"))
plot(data_dba)
if (plot_v) dev.off()

#############################
### DIFFERENTIAL ANALYSIS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############################

### Identify which cell lines belong to which groups
data_dba <- dba.contrast(data_dba, categories = DBA_CONDITION, minMembers = 2)

### Perform differential analysis
data_dba <- dba.analyze(data_dba)

### View results
data_dba
dim(data_dba$merged)

### Plot correlation heatmap of results
if (plot_v) pdf(file = file.path(diffPlotDir_v, "diffBind_CorrelationHeat.pdf"))
plot(data_dba, contrast = 1)
if (plot_v) dev.off()

### Extract differentially-bound sites
dbSites_gr <- dba.report(data_dba)

### Make peak names
peakNames_v <- paste0("dbPeak_", 1:length(dbSites_gr))

### Write out peaks
dbSites_bed <- data.frame(seqnames = seqnames(dbSites_gr),
                          starts = start(dbSites_gr)-1,
                          ends = end(dbSites_gr),
                          peak = peakNames_v,
                          names = rep(".", times = length(dbSites_gr)),
                          strand = rep("*", times = length(dbSites_gr)))

### Print
print("Dimensions of bed output:")
print(dim(dbSites_bed))

### Write
write.table(dbSites_bed, file = file.path(outDir_v, "diffBindSites.bed"),
            sep = '\t', quote = F, row.names = F, col.names = F)
if (!is.null(homerDir_v)){
  out_dbSites_bed <- dbSites_bed
  out_dbSites_bed$seqnames <- gsub("^chr", "", out_dbSites_bed$seqnames)
  setkey(out_dbSites_bed, key = "seqnames")
  write.table(out_dbSites_bed, file = file.path(homerDir_v, "diffBind_positions_sigDiff.bed"),
              sep = '\t', quote = F, row.names = F, col.names = F)
}

#############
### PLOTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

###
### PCA
###

if (plot_v) pdf(file = file.path(diffPlotDir_v, "treatCompare_PCA.pdf"))
### all peaks
dba.plotPCA(data_dba,DBA_CONDITION,label=DBA_ID)

### diffbind peaks only
dba.plotPCA(data_dba, contrast = 1, label=DBA_REPLICATE)
if (plot_v) dev.off()

###
### MA Plots
###

### Standard
if (plot_v) pdf(file = file.path(diffPlotDir_v, "normQC_MA.pdf"))
dba.plotMA(data_dba)
if (plot_v) dev.off()

###
### Volcano Plots
###

if (plot_v) pdf(file = file.path(diffPlotDir_v, "degCheck_volcano.pdf"))
dba.plotVolcano(data_dba)
if (plot_v) dev.off()

###
### BoxPlots
###

### Commented out because not very informative.

#if (plot_v) pdf(file = file.path(outDir_v, "degCheck_bindingAffinity.pdf"))
#pvals <- dba.plotBox(data_dba)
#if (plot_v) dev.off()

###
### Heatmaps
###

### Binding Affinity Heatmap
### Shows affinities and clustering of the diff-bound sites (rows)
if (plot_v) pdf(file = file.path(diffPlotDir_v, "degCheck_baHeat.pdf"))
corvals <- dba.plotHeatmap(data_dba, contrast = 1, correlations = F, scale = "row",
                           main = "Row-Scale Heatmap of \nBinding Affinity")
if (plot_v) dev.off()

##################
### ANNOTATION ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##################

### Get Annotation Data
annoData <- toGRanges(EnsDb.Hsapiens.v86, feature = "gene")

### Annotate peaks to promoter regions
dbSites_anno <- annotatePeakInBatch(dbSites_gr,
                                    AnnotationData = annoData,
                                    output = "nearestBiDirectionalPromoters",
                                    bindingRegion = c(-2000,500))

### Load mart
ensembl <- useMart(biomart = "ensembl",
                   dataset = "hsapiens_gene_ensembl")

### Add Gene Info
dbSites_anno <- addGeneIDs(annotatedPeak = dbSites_anno, 
                           orgAnn = "org.Hs.eg.db",
                           feature_id_type = "ensembl_gene_id", # (default)
                           IDs2Add = c("entrez_id", "entrezgene"))

### Turn into data.table and write output
dbSites_anno_dt <- as.data.table(unname(dbSites_anno))
xlsxName_v <- file.path(path.expand(outDir_v), "diffBind_annotation.xlsx")
textName_v <- file.path(outDir_v, "diffBind_anno.txt")
write.xlsx(dbSites_anno_dt, file = xlsxName_v, sheetName = "raw", row.names = F)
write.table(dbSites_anno_dt, file = textName_v, sep = '\t', quote = F, row.names = F)

### Write output for homer
if (!is.null(homerDir_v)){
  write.table(dbSites_anno_dt$gene_name, file = file.path(homerDir_v, "diffBind_geneName_sigDiff.txt"),
              sep = '\t', quote = F, row.names = F, col.names = F)
  write.table(dbSites_anno_dt[!is.na(entrez_id), entrez_id], file = file.path(homerDir_v, "diffBind_entrezID_sigDiff.txt"),
              sep = '\t', quote = F, row.names = F, col.names = F)
}

### Print out venn diagram of common peaks around features
if (plot_v) pdf(file = file.path(annotPlotDir_v, "dbSite_commonPeakFeaturePie.pdf"))
pie1(table(dbSites_anno$insideFeature),
     main = "Cmmon Peak-Feature Distribution For Diff-Bound Sites")
if (plot_v) dev.off()

#####################
### GO ENRICHMENT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#####################

### Obtain enriched GO terms and write
dbSites_anno.GO <- getEnrichedGO(dbSites_anno, 
                                 orgAnn = "org.Hs.eg.db",
                                 maxP = 0.05, minGOterm = 10,
                                 multiAdjMethod = "BH", condense = T)

### Get names of GO databases
goNames_v <- names(dbSites_anno.GO)

### Write out
for (i in 1:length(goNames_v)){
  currName_v <- goNames_v[i]
  write.xlsx(dbSites_anno.GO[[currName_v]],
             file = xlsxName_v,
             sheetName = paste("GO_", currName_v),
             row.names = F,
             append = T)
}

### Get Reactome.db enriched pathways
dbSites_anno.Path <- getEnrichedPATH(dbSites_anno,
                                     orgAnn = "org.Hs.eg.db",
                                     pathAnn = "reactome.db",
                                     maxP = 0.05)

write.xlsx(dbSites_anno.Path, file = xlsxName_v, sheetName = "ReactomeDB", row.names = F, append = T)

