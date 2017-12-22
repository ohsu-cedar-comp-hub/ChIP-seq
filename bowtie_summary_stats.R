###
### Aggregate Summary Statistics About Alignment Results
###

### Dependencies
library(data.table)

### Arguments
arguments <- commandArgs(trailingOnly = T)
input_dir_v <- arguments[1]             # should be data/<combined/raw>/qc/mapq_qc/ (or no combined/raw if not applicable)
output_dir_v <- arguments[2]            # should be data/<combined/raw>/qc/
lane_v <- F                             # True means multiple lanes ran, so keep lane in sample name. False uses shorter sample name

### Wrangling
input_files_v <- list.files(input_dir_v)
file_names_v <- sapply(input_files_v, function(x){
    temp.split <- unlist(strsplit(x, split = "_"))
    if (lane_v) {
        out.name <- paste(temp.split[2], temp.split[3], temp.split[5], sep = "_")
    } else {
        out.name <- paste(temp.split[2], temp.split[3], sep = "_")
    } # fi
    return(out.name)}, USE.NAMES=F)


### Operations
total_data_dt <- data.table("Num.Reads" = NA, "MapQ.Score" = NA)

for (i in 1:length(input_files_v)){
    curr_file_v <- input_files_v[i]
    curr_data_dt <- fread(paste0(input_dir_v, curr_file_v))
    colnames(curr_data_dt) <- c("Num.Reads", "MapQ.Score")
    total_data_dt <- merge(total_data_dt, curr_data_dt, by = "MapQ.Score", all = T, suffixes = c(i, i+1))
}

total_data_dt <- total_data_dt[2:nrow(total_data_dt),]
total_data_dt <- total_data_dt[,`Num.Reads1`:= NULL]
total_data_dt[is.na(total_data_dt)] <- 0

colnames(total_data_dt) <- c("MapQ.Score", file_names_v)

write.table(total_data_dt, file = paste0(output_dir_v, "mapq_summary.txt"), quote = F, sep = '\t', row.names = F)
