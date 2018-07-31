###
### Create venn diagrams of overlapping peaks
###

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

source("https://bioconductor.org/biocLite.R")
suppressMessages(library(ChIPpeakAnno))
suppressMessages(library(EnsDb.Hsapiens.v86))
suppressMessages(library(TxDb.Hsapiens.UCSC.hg38.knownGene))
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
    c("-o", "--outDir"),
    type = "character",
    help = "Path to where output files will be written"),
  make_option(
    c("-h", "--homerDir"),
    type = "character",
    help = "Optional. If specified, will write bed file to this directory for subsequent homer analysis. 
          If not specified, will write to normal output directory only."
  )
)

### Parse Command Line
p <- OptionParser(usage = "%prog -i inputDir -t treatIndex -s sampleIndex -o outDir -h homerDir",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options
                  
inputDir_v <- args$inputDir
tID_v <- args$treatIndex
sID_v <- args$sampleIndex
outDir_v <- args$outDir
homerDir_v <- args$homerDir

###################
### PRE-PROCESS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###################

inputFiles_v <- list.files(inputDir_v)

### Get names
fullNames_v <- gsub("_peaks.narrowPeak", "", inputFiles_v)
treatNames_v <- unlist(sapply(fullNames_v, function(x) strsplit(x, split = "_")[[1]][tID_v], simplify = F))
sampleNames_v <- unlist(sapply(fullNames_v, function(x) strsplit(x, split = "_")[[1]][sID_v], simplify = F))

### Read in data
inputData_lsGR <- sapply(inputFiles_v, function(x) toGRanges(file.path(inputDir_v, x), format = "BED", header = F), simplify = F)
names(inputData_lsGR) <- fullNames_v

### Subset for only chromosomes that we expect
goodChr_v <- c(paste0("chr", 1:22), "chrX")
subData_lsGR <- sapply(inputData_lsGR, function(x) x[seqnames(x) %in% goodChr_v], simplify = F)

### Identify treatments and arrange into list
treats_v <- unique(treatNames_v)
inputData_lslsGR <- list()
for (treat_v in treats_v){
  currData_v <- grep(treat_v, names(subData_lsGR), value = T)
  inputData_lslsGR[[treat_v]] <- subData_lsGR[currData_v]
}

### Get annotation data
annoData <- toGRanges(EnsDb.Hsapiens.v86, feature = "gene")

#########################
### OVERLAPPING PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########################

### For each treatment, combine gRanges objects to see which peaks overlap. Then compare those results b/w treatments

### Find overlap within each treatment
treatOverlap_lsGR <- list()
for (treat_v in treats_v){
  ## Get data
  currData_lsGR <- inputData_lslsGR[[treat_v]]
  ## Find overlap
  treatOverlap_lsGR[[treat_v]] <- suppressWarnings(findOverlapsOfPeaks(currData_lsGR[[1]],
                                                                       currData_lsGR[[2]]))
  ## Add metadata
  treatOverlap_lsGR[[treat_v]] <- addMetadata(treatOverlap_lsGR[[treat_v]], colNames = "score", FUN=mean)
} # for

### Make venn diagram of each treatment individually
versions_v <- c("min", "merge", "keepAll")
for (treat_v in treats_v){
  currOverlap_lsGR <- treatOverlap_lsGR[[treat_v]]
  currNames_v <- sampleNames_v[grep(treat_v, names(sampleNames_v))]
  for (version_v in versions_v) {
    pdf(file = file.path(outDir_v, paste(treat_v, version_v, "peakOverlapVenn.pdf")))
    makeVennDiagram(currOverlap_lsGR, NameOfPeaks = currNames_v, 
                    main = paste0("Overlapping peaks for ", treat_v, "\nUsing Option: ", version_v),
                    print.mode = c("raw", "percent"),
                    connectedPeaks = version_v)
    dev.off()
  } # for version
} # for treat

### Rename the overlap results, for easier output
names(treatOverlap_lsGR$CM$peaklist) <- c("S29", "S28", "CM_share")
names(treatOverlap_lsGR$DMEM$peaklist) <- c("S26", "S25", "DMEM_share")

### Combine the overlaps
totalOverlap_lsGR <- findOverlapsOfPeaks(treatOverlap_lsGR$CM$peaklist$CM_share,
                                         treatOverlap_lsGR$DMEM$peaklist$DMEM_share)

### Make a venn diagram of overlapping peaks
pdf(file = file.path(outDir_v, "total_peakOverlapVenn.pdf"))
makeVennDiagram(totalOverlap_lsGR, NameOfPeaks = c("CM", "DMEM"), 
main = paste0("Peaks Common Among Replicates \nOverlapping Between CM and DMEM"),
                print.mode = c("raw", "percent"))
dev.off()

#######################
### WRITE OUT PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#######################

### Get peaks
commonPeaks_gr <- totalOverlap_lsGR$mergedPeaks

### Make peak names
peakNames_v <- paste0("commonPeak_", 1:length(commonPeaks_gr))

### Write out peaks
commonPeaks_bed <- data.frame(seqnames = seqnames(commonPeaks_gr),
                              starts = start(commonPeaks_gr)-1,
                              ends = end(commonPeaks_gr),
                              peak = peakNames_v,
                              names = rep(".", times = length(commonPeaks_gr)),
                              strand = rep("*", times = length(commonPeaks_gr)))

### Remove "chr" from names
commonPeaks_bed$seqnames <- gsub("chr", "", commonPeaks_bed$seqnames)

### Write
write.table(commonPeaks_bed, file = file.path(outDir_v, "commonPeaks_bothTreats.bed"),
            sep = '\t', quote = F, row.names = F, col.names = F)
if (!is.null(homerDir_v)) {
  write.table(commonPeaks_bed, file = file.path(homerDir_v, "commonPeaks_positions_bothTreats.bed"),
            sep = '\t', quote = F, row.names = F, col.names = F)
}


###############################
### VISUALIZE BINDING SITES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################

### Subset for peak list
overLapPeakList <- totalOverlap_lsGR$peaklist[[3]]

### Visualize binding site distribution relative to features (e.g. distance to nearest TSS)
pdf(file = file.path(outDir_v, paste0(treat_v, "_PeakToFeatureDistance.pdf")))
binOverFeature(overLapPeakList, annotationData = annoData,
               radius = 5000, nbins = 20, FUN = length, errFun = 0,
               ylab = "Count", main = paste0("Distr of aggregated peak numbers around TSS\nFor ", treat_v, " Treatment"))
dev.off()

### Summarize distribution of peaks over different types of features
### Peaks can span multiple feature types, so # of annotated features can be greater than # input peaks
aCR <- assignChromosomeRegion(overLapPeakList, nucleotideLevel = F,
                                          precedence = c("Promoters", "immediateDownstream", "fiveUTRs",
                                                         "threeUTRs", "Exons", "Introns"),
                                          TxDb = TxDb.Hsapiens.UCSC.hg38.knownGene)

ymax_v <- ceiling(max(aCR$percentage)/10)*10

pdf(file = file.path(outDir_v, paste0(treat_v, "_peakFeatureTypeDistribution.pdf")))
barplot(aCR$percentage, las = 2, ylab = "Percentage of Peaks", ylim=c(0,ymax_v),
        main = paste0("Peak Distribution Among Different Features\nFor ", treat_v, " Treatment"))
dev.off()

######################
### ANNOTATE PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
######################

### Annotate peaks to the promoter regions of genes
### specify promoters using bindingRegion argument (2000 upstream and 500 downstream)
overLapPeakList.anno <- annotatePeakInBatch(overLapPeakList,
                                            AnnotationData = annoData,
                                            output = "nearestBiDirectionalPromoters",
                                            bindingRegion = c(-2000,500))

### Add Entrez IDs
overLapPeakList.anno <- addGeneIDs(overLapPeakList.anno,
                                   "org.Hs.eg.db",
                                   IDs2Add = "entrez_id")

### Turn into data.table and write output
overLapPeakList.anno_dt <- as.data.table(unname(overLapPeakList.anno))
xlsxName_v <- file.path(path.expand(outDir_v), "commonPeaks_annotation.xlsx")
write.xlsx2(overLapPeakList.anno_dt, file = xlsxName_v, sheetName = "raw", row.names = F)
write.table(overLapPeakList.anno_dt, file = file.path(outDir_v, "commonPeaks_anno.txt"),
            sep = '\t', quote = F, row.names = F)

### Write just gene names and entrez ids to files for homer
if (!is.null(homerDir_v)){
  write.table(overLapPeakList.anno_dt$gene_name, file = file.path(homerDir_v, "commonPeaks_geneName_bothTreats.txt"),
              sep = '\t', quote = F, row.names = F, col.names = F)
  write.table(overLapPeakList.anno_dt[!is.na(entrez_id), entrez_id], file = file.path(homerDir_v, "commonPeaks_entrezID_bothTreats.txt"),
              sep = '\t', quote = F, row.names = F, col.names = F)
}

### Visualize distribution of common peaks around features
pdf(file = file.path(outDir_v, paste0(treat_v, "_commonPeakFeaturePie.pdf")))
pie1(table(overLapPeakList.anno$insideFeature),
     main = paste0("Common Peak-Feature Distribution\nFor ", treat_v, " Treatment"))
dev.off()

#####################
### GO ENRICHMENT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#####################

### Obtain enriched GO terms and write
overLapPeakList.GO <- getEnrichedGO(overLapPeakList.anno, orgAnn = "org.Hs.eg.db",
                                    maxP = 0.05, minGOterm = 10,
                                    multiAdjMethod = "BH", condense = T)
goNames_v <- names(overLapPeakList.GO)

### Write out
for (i in 1:length(goNames_v)){
  currName_v <- goNames_v[i]
  write.xlsx2(overLapPeakList.GO[[currName_v]],
              file = xlsxName_v,
              sheetName = paste("GO_", currName_v),
              row.names = F,
              append = T)
}

### Obtain enriched pathways from Reactome.db
overLapPeakList.Path <- getEnrichedPATH(overLapPeakList.anno, "org.Hs.eg.db", "reactome.db", maxP = 0.05)
write.xlsx2(overLapPeakList.Path, file = xlsxName_v, sheetName = "ReactomeDB", row.names = F, append = T)

### Obtain sequences surrounding peaks
### This takes a while and just outputs a FASTA file that I never used.
# overLapPeakList.peakSeqs <- getAllPeakSequence(overLapPeakList, upstream = 20, downstream = 20, genome=Hsapiens)
# write2FASTA(overLapPeakList.peakSeqs, file.path(outDir_v, paste0(treat_v, "_peakSequences.fa")))

