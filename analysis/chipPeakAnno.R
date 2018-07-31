###
### Run ChIP Peak Annotation Workflow
###

### Taken from: https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/pipeline.html
### ChIPpeakAnno 3.14.0

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

suppressMessages(library(rtracklayer))
suppressMessages(library(ChIPpeakAnno))
suppressMessages(library(biomaRt))
suppressMessages(library(motifStack))
suppressMessages(library(EnsDb.Hsapiens.v86))
suppressMessages(library(TxDb.Hsapiens.UCSC.hg38.knownGene))
suppressMessages(library(org.Hs.eg.db))
suppressMessages(library(data.table))
suppressMessages(library(reactome.db))
suppressMessages(library(BSgenome.Hsapiens.UCSC.hg38))
suppressMessages(library(optparse))

#################
### ARGUMENTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#################

### Make list of options
optlist <- list(
  make_option(
    c("-i", "--inputDir"),
    type = "character",
    help = "Path to directory containing input files, which contain identified peaks. Will usually be the output of MACS2. 
    Specific files to use will be specified with treatment argument."
  ),
  make_option(
    c("-t", "--treatIndex"),
    type = "numeric",
    help = "Index of treatment identifier in file name, assuming name is separated by '_'. Used to split files for analysis"
  ),
  make_option(
    c("-s", "--sampleIndex"),
    type = "numeric",
    help = "Index of sample identifier in file name, assuming name is separated by '_'."
  ),
  make_option(
    c("-r", "--treat"),
    type = "character",
    help = "Character vector of treatment that should be analyzed."
  ),
  make_option(
    c("-w", "--write"),
    type = "logical",
    default = T,
    help = "logical. TRUE - write out tables; FALSE - do not write tables to file."
  ),
  make_option(
    c("-", "--plot"),
    type = "logical",
    default = T,
    help = "logical. TRUE - write out plots; FALSE - do not write plots to file."
  ),
  make_option(
    c("-o", "--outDir"),
    type = "character",
    help = "Path to where output files will be written"))

### Parse Command Line
p <- OptionParser(usage = "%prog -i inputDir -t treatIndex -s sampleIndex -w write -p plot -o outDir",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options
                  
inputDir_v <- args$inputDir
tID_v <- args$treatIndex
sID_v <- args$sampleIndex
treat_v <- args$treat
write_v <- args$write
plot_v <- args$plot
outDir_v <- args$outDir

### For testing
# inputDir_v <- "~/projs/Sherman/DNA180319MS/chipPeakAnno_analysis/input/toUse/"
# outDir_v <- "~/projs/Sherman/DNA180319MS/chipPeakAnno_analysis/output/"
# tID_v <- 2
# sID_v <- 5
# write_v <- T
# plot_v <- F
# treat_v <- "DMEM"

### Extra testing
#testGenes_dt <- fread("~/projs/Sherman/DNA180319MS/meta/genesToSearch_CM_anno_peakInfo.txt")
                  
###################
### PRE-PROCESS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################

print("Begin pre-process")

### Get input files
inputFiles_v <- list.files(inputDir_v)

### Get names
fullNames_v <- gsub("_peaks.narrowPeak", "", inputFiles_v)
treatNames_v <- unlist(sapply(fullNames_v, function(x) strsplit(x, split = "_")[[1]][tID_v], simplify = F))
sampleNames_v <- unlist(sapply(fullNames_v, function(x) strsplit(x, split = "_")[[1]][sID_v], simplify = F))

### Specify which to keep
toKeep_v <- which(treatNames_v == treat_v)

### Subset
inputFiles_v <- inputFiles_v[toKeep_v]
fullNames_v <- fullNames_v[toKeep_v]
treatNames_v <- treatNames_v[toKeep_v]
sampleNames_v <- sampleNames_v[toKeep_v]

### Read in data
inputData_lsGR <- sapply(inputFiles_v, function(x) toGRanges(file.path(inputDir_v, x), format = "BED", header = F), simplify = F)
names(inputData_lsGR) <- fullNames_v

### Subset for only chromosomes that we expect
goodChr_v <- c(paste0("chr", 1:22), "chrX")
subData_lsGR <- sapply(inputData_lsGR, function(x) x[seqnames(x) %in% goodChr_v], simplify = F)

### Get annotation data
annoData <- toGRanges(EnsDb.Hsapiens.v86, feature = "gene")

###############################
### CHECK FOR MISSING GENES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################

### A few genes of interest were not found to be differentially bound in diffBind. Wanted to check
### them in this analysis script as well to see if we can determine what is happening to their peaks.
### Uses the "testGenes_dt" file that is commented above. The columns of that file are:
### gene_name	entrez_id	ensembleID	chr	start	end	igv	length
### "igv" is of the format chr:start-end, which makes it easy to copy-paste into the igv search bar.
### The only columns required for this script are:
### chr start end ensembleID

# ### Convert to data.table for easier subsetting
# inputData_lsdt <- sapply(inputData_lsGR, function(x) as.data.table(x), simplify = F)
# 
# for (i in 1:length(inputData_lsdt)){
#   currName_v <- names(inputData_lsdt)[i]
#   currData_dt <- inputData_lsdt[[currName_v]]
#   for (j in 1:nrow(testGenes_dt)){
#     currGene_v <- testGenes_dt[j,]
#     cat(sprintf("Working on sample: %s\n", currName_v))
#     cat(sprintf("\tChecking for gene: %s\n", currGene_v$gene_name))
#     currHits_dt <- currData_dt[seqnames == currGene_v$chr &
#                                  start <= currGene_v$start &
#                                  end <= currGene_v$end,]
#     print(currHits_dt)
#   } # for j
# } # for i

#########################
### OVERLAPPING PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########################

### Compare input gRanges objects and output a venn diagram showing the number of peaks common between replicates.

### Find overlap
overLap <- suppressWarnings(findOverlapsOfPeaks(subData_lsGR[[1]], subData_lsGR[[2]]))

### Add metadata (mean of score) to the overlapping peaks
overLap <- addMetadata(overLap, colNames = "score", FUN=mean)

### Preview overlapping peaks
head(overLap$peaklist[[3]])

### Make a venn diagram of overlapping peaks
if (plot_v) pdf(file = file.path(outDir_v, paste0(treat_v, "_peakOverlapVenn.pdf")))
makeVennDiagram(overLap, NameOfPeaks = sampleNames_v, main = paste0("Overlapping peaks for\n", treat_v, " Treatment"),
                print.mode = c("raw", "percent"))
if (plot_v) dev.off()

###############################
### VISUALIZE BINDING SITES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################

### Subset for peak list
overLapPeakList <- overLap$peaklist[[3]]
# overLaps <- overLap$peaklist[[3]]

### Visualize binding site distribution relative to features (e.g. distance to nearest TSS)
if (plot_v) pdf(file = file.path(outDir_v, paste0(treat_v, "_PeakToFeatureDistance.pdf")))
binOverFeature(overLapPeakList, annotationData = annoData,
               radius = 5000, nbins = 20, FUN = length, errFun = 0,
               ylab = "Count", main = paste0("Distr of aggregated peak numbers around TSS\nFor ", treat_v, " Treatment"))
if (plot_v) dev.off()

### Summarize distribution of peaks over different types of features
### Peaks can span multiple feature types, so # of annotated features can be greater than # input peaks
aCR <- assignChromosomeRegion(overLapPeakList, nucleotideLevel = F,
                                          precedence = c("Promoters", "immediateDownstream", "fiveUTRs",
                                                         "threeUTRs", "Exons", "Introns"),
                                          TxDb = TxDb.Hsapiens.UCSC.hg38.knownGene)

ymax_v <- ceiling(max(aCR$percentage)/10)*10

if (plot_v) pdf(file = file.path(outDir_v, paste0(treat_v, "_peakFeatureTypeDistribution.pdf")))
barplot(aCR$percentage, las = 2, ylab = "Percentage of Peaks", ylim=c(0,ymax_v),
        main = paste0("Peak Distribution Among Different Features\nFor ", treat_v, " Treatment"))
if (plot_v) dev.off()

######################
### ANNOTATE PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
######################

### Annotate peaks to the promoter regions of genes
### specify promoters using bindingRegion argument (2000 upstream and 500 downstream)
### Original method was only bi-directional promoters, added shortest, nearest, and overlapping.
### These were just added to check and see what different parameters do to the output.
### 
overLapPeakList.anno.bdp <- annotatePeakInBatch(overLapPeakList,
                                                AnnotationData = annoData,
                                                output = "nearestBiDirectionalPromoters",
                                                bindingRegion = c(-2000,500))

# overLapPeakList.anno.sd <- annotatePeakInBatch(overLapPeakList,
#                                                AnnotationData = annoData,
#                                                output = "shortestDistance")
# 
# overLapPeakList.anno.nl <- annotatePeakInBatch(overLapPeakList,
#                                                AnnotationData = annoData,
#                                                output = "nearestLocation")
# 
# overLapPeakList.anno.o <- annotatePeakInBatch(overLapPeakList,
#                                               AnnotationData = annoData,
#                                               output = "overlapping")
# 
# overLapPeakList.anno.b <- annotatePeakInBatch(overLapPeakList,
#                                               AnnotationData = annoData,
#                                               output = "both")

# overlap_ls <- list("bdp" = overLapPeakList.anno.bdp,
#                    "sd" = overLapPeakList.anno.sd,
#                    "nl" = overLapPeakList.anno.nl,
#                    "o" = overLapPeakList.anno.o,
#                    "b" = overLapPeakList.anno.b)
overlap_ls <- list("bdp" = overLapPeakList.anno.bdp)

### Check genes
# for (i in 1:length(overlap_ls)){
#   currName_v <- names(overlap_ls)[i]
#   currData_dt <- as.data.table(overlap_ls[[currName_v]])
#   print(sprintf("Working on: %s", currName_v))
#   sub_dt <- currData_dt[feature %in% testGenes_dt$ensembleID,]
#   print(sub_dt[,mget(c("seqnames", "start", "end", "feature"))])
# }

### Add Entrez IDs
overlap_ls <- sapply(overlap_ls, function(x) {
  y <- addGeneIDs(x, "org.Hs.eg.db", IDs2Add = c("entrez_id", "symbol"))
  return(y)
}, simplify = F)



### Turn into data.table and write output
overlap_lsdt <- sapply(overlap_ls, function(x) as.data.table(unname(x)), simplify = F)
if (write_v) { sapply(names(overlap_lsdt), function(x) write.table(overlap_lsdt[[x]], 
                                                    file = file.path(outDir_v, paste(treat_v, x, "anno.txt", sep = "_")),
                                                    sep = '\t', quote = F, row.names = F))}

### Visualize distribution of common peaks around features
if (plot_v) pdf(file = file.path(outDir_v, paste0(treat_v, "_commonPeakFeaturePie.pdf")))
pie1(table(overLapPeakList.anno.bdp$insideFeature),
     main = paste0("Common Peak-Feature Distribution\nFor ", treat_v, " Treatment"))
if (plot_v) dev.off()

#####################
### GO ENRICHMENT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#####################

### Obtain enriched GO terms and write
overLapPeakList.GO <- getEnrichedGO(overLapPeakList.anno.bdp, orgAnn = "org.Hs.eg.db",
                                    maxP = 0.05, minGOterm = 10,
                                    multiAdjMethod = "BH", condense = T)
goNames_v <- names(overLapPeakList.GO)
if (write_v) sapply(goNames_v, function(x) write.table(overLapPeakList.GO[[x]], file = file.path(outDir_v, paste0(treat_v, "_GO_Enrich_", x, ".txt")), sep = '\t', quote = F, row.names = F))

### Obtain enriched pathways from Reactome.db
overLapPeakList.Path <- getEnrichedPATH(overLapPeakList.anno.bdp, "org.Hs.eg.db", "reactome.db", maxP = 0.05)
if (write_v) write.table(overLapPeakList.Path, file = file.path(outDir_v, paste0(treat_v, "_Reactome_Pathways.txt")), sep = '\t', quote = F, row.names = F)

### Obtain sequences surrounding peaks
# overLapPeakList.peakSeqs <- getAllPeakSequence(overLapPeakList, upstream = 20, downstream = 20, genome=Hsapiens)
# write2FASTA(overLapPeakList.peakSeqs, file.path(outDir_v, paste0(treat_v, "_peakSequences.fa")))

#############################
### OUTPUT PEAK CONSENSUS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############################

# ### Get reference frequencies
# oligoFreqs_mat <- sapply(goodChr_v, function(x) oligoFrequency(Hsapiens[[x]], MarkovOrder = 3))
# oligoFreqs_v <- rowMeans(oligoFreqs_mat, na.rm = T)
# rm(oligoFreqs_mat)
# 
# ### Compare to our data
# oligoSummary_ls <- oligoSummary(overLapPeakList.peakSeqs, oligoLength = 6, MarkovOrder = 3,
#                                 quickMotif = F, freqs = oligoFreqs_v)
# 
# # ### Create motifs for a subset
# # set.seed(10)
# # toSub_v <- sample(1:length(overLapPeakList.peakSeqs), 2000, replace = F)
# # subOverLapPeakList.peakSeqs <- overLapPeakList.peakSeqs[toSub_v]
# # subOligoSummary_ls <- oligoSummary(subOverLapPeakList.peakSeqs, oligoLength = 6, MarkovOrder = 3,
# #                                    quickMotif = T, freqs = oligoFreqs_v)
# 
# ### Plot results
# oligoSummary_zs <- sort(oligoSummary_ls$zscore)
# pdf(file = file.path(outDir_v, paste0(treat_v, "_oligoZScoreHist.pdf")))
# oligoHist <- hist(oligoSummary_zs, breaks = 100, xlab = "Z-Score",
#                   main = paste0("Histogram of Oligo Z-Scores\nFor ", treat_v, " Treatment"))
# text(oligoSummary_zs[length(oligoSummary_zs)], max(oligoHist$counts)/10,
#      labels = names(oligoSummary_zs[length(oligoSummary_zs)]), adj = 1)
# dev.off()
# 
# # ### Plot subset also
# # subOligoSummary_zs <- sort(subOligoSummary_ls$zscore)
# # pdf(file = file.path(outDir_v, paste0(treat_v, "_subsetOligoZScoreHist.pdf")))
# # subOligoHist <- hist(subOligoSummary_zs, breaks = 100, xlab = "Z-Score",
# #                      main = paste0("Histogram of Oligo Z-Scores\nFor ", treat_v, " Treatment"))
# # text(subOligoSummary_zs[length(subOligoSummary_zs)], max(subOligoHist$counts)/10,
# #      labels = names(subOligoSummary_zs[length(subOligoSummary_zs)]), adj = 1)
# 
# ### Simulated Frequencies
# seqSimMotif <- list(c("t", "g", "c", "a", "t", "g"),
#                     c("g", "c", "a", "t", "g", "c"))
# set.seed(1)
# seqSim <- sapply(sample(c(2,1,0), 1000, replace = T, prob=c(0.07,0.1,0.83)), function(x){
#   s <- sample(c("a", "c", "g", "t"),
#               sample(100:1000,1),replace = T)
#   if (x > 0) {
#     si <- sample.int(length(x), 1)
#     if (si > (length(s)-6)) {
#       si <- length(s)-6
#     } # fi
#     s[si:(si+5)] <- seqSimMotif[[x]]
#   } # fi
#   paste(s, collapse = "")
# })
# 
# simSummary_ls <- oligoSummary(seqSim, oligoLength = 6, MarkovOrder = 3, quickMotif = T)
# simSummary_zs <- sort(simSummary_ls$zscore, decreasing = T)
# pdf(file = file.path(outDir_v, "simulatedMotifZScore.pdf"))
# simHist <- hist(simSummary_zs, breaks = 100, main = "Histogram of Simulated Motif Z-Scores")
# text(simSummary_zs[1:2], rep(5,2),
#      labels = names(simSummary_zs[1:2]), adj = 0, srt = 90)
# dev.off()

#######################
### Generate Motifs ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#######################

# ### Subset 
# subMotifs_ls <- mapply(function(.ele, id)
#   new("pfm", mat=.ele, name=paste0(treat_v, " motif - ", id)),
#   subOligoSummary_ls$motifs, 1:length(subOligoSummary_ls$motifs))
# 
# motifStack(subMotifs_ls[[1]])

