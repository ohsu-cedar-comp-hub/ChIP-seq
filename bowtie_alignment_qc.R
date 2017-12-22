### Extract run information from condor error files created by bowtie2
### Will grab data on # aligned, # multi-mapped, and # unaligned (as well as percentages)

### Get command-line arguments
arguments <- commandArgs(trailingOnly=TRUE);
input.dir <- arguments[1];              # should be a directory containing only and all bowtie2_<cluster.num>.<job.num>.err files,
                                        # as well as test_bowtie2 versions.
file.dir <- arguments[2]                # path to 10_sam files (just for sample names)
out.dir <- arguments[3]                 # should be qc/ directory within data.

### Examine the current directory for the files to process
files.in.dir <- list.files(input.dir, pattern="*.err");
files.in.dir <- files.in.dir[order(as.numeric(gsub("bowtie2_[0-9]+_|\\.err", "", files.in.dir)))]

### Get names
file.names <- list.files(file.dir, pattern="*.sam")
names_v <- sapply(file.names, function(x) paste(strsplit(x, split = "_")[[1]][2:3], collapse = "_"), USE.NAMES=F)


output.df <- data.frame(sample=character(),                 # 1
                        total.reads=integer(),
                        no.alignment=integer(),
                        no.alignment.pct=integer(),
                        single.alignment=integer(),         # 5
                        single.alignment.pct=integer(),
			multiple.alignment=integer(),
                        multiple.alignment.pct=integer(),
                        overall.alignment.pct=integer(),
                        stringsAsFactors=FALSE);

for(i in 1:length(files.in.dir))	{
    ##   get a QC file to process
    curr.file <- file.path(input.dir, files.in.dir[i]);
    curr.split <- strsplit(basename(curr.file), "\\.|_")[[1]]
                                        #    curr.name <- paste(curr.split[1], curr.split[3], sep = "_")
    curr.name <- names_v[i]
    
    curr.record <- readLines(curr.file);

    ##   misc QC
    if(length(curr.record) != 6)   {
        stop("Unexpected length of report for file: ", curr.file, "\n", sep="");
    }   #   fi

    ## Get info
    curr.total <- strsplit(curr.record[1], " ")[[1]][1]

    curr.no.align.full <- unlist(strsplit(trimws(curr.record[3]), " "))
    curr.no.align <- curr.no.align.full[1]
    curr.pct.no.align <- as.numeric(gsub("\\(|\\)|%", '', curr.no.align.full[2]))

    curr.one.align.full <- unlist(strsplit(trimws(curr.record[4]), " "))
    curr.one.align <- curr.one.align.full[1]
    curr.pct.one.align <- as.numeric(gsub("\\(|\\)|%", '', curr.one.align.full[2]))

    curr.mult.align.full <- unlist(strsplit(trimws(curr.record[5]), " "))
    curr.mult.align <- curr.mult.align.full[1]
    curr.pct.mult.align <- as.numeric(gsub("\\(|\\)|%", '', curr.mult.align.full[2]))

    curr.overall <- gsub("%", "", unlist(strsplit(trimws(curr.record[6]), " "))[1])

    ## Add to output
    output.df[i,]$sample <- curr.name
    output.df[i,]$total.reads <- curr.total
    output.df[i,]$no.alignment <- curr.no.align
    output.df[i,]$no.alignment.pct <- curr.pct.no.align 
    output.df[i,]$single.alignment <- curr.one.align
    output.df[i,]$single.alignment.pct <- curr.pct.one.align 
    output.df[i,]$multiple.alignment <- curr.mult.align
    output.df[i,]$multiple.alignment.pct <- curr.pct.mult.align 
    output.df[i,]$overall.alignment.pct <- curr.overall 
     
}	#	for i

write.table(output.df, 
            file=file.path(out.dir, "bowtie2.alignment.QC.summary.txt"),
            quote=FALSE,
            sep="\t",
            row.names=FALSE)

