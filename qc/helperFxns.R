#!/usr/bin/Rscript

###
### Standard ggplot theme #######################################################################################################
###

my_theme <- theme_classic() +
    theme(plot.title = element_text(hjust = 0.5, size = 18),
          axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 14))

###
### Big Label  ggplot theme #####################################################################################################
###

big_label <- theme_classic() +
    theme(plot.title = element_text(hjust = 0.5, size = 20),
          axis.text = element_text(size = 16),
          axis.text.y = element_text(angle = 45),
          axis.title = element_text(size = 18),
          legend.text = element_text(size = 16),
          legend.title = element_text(size = 18))

###
### Angle Text theme ############################################################################################################
###

angle_x <- theme(axis.text.x = element_text(angle = 45, hjust = 1))
angle_y <- theme(axis.text.y = element_text(angle = 45))
angle_both <- theme(axis.text.x = element_text(angle = 45, hjust = 1),
                    axis.text.y = element_text(angle = 45))

###
### makeDir ##################################################################################################################
###

mkdir <- function(base_dir_v, 
                  new_dir_v){
    #' Creates new directory in which to write files
    #' @description
    #' Given a base directory and string, will check if specified directory exits, and make it if not.
    #' @param base_dir_v Character string. Relative or absolute path to directory that will hold new directory
    #' @param new_dir_v Character string. Name of new directory.
    #' @return Character string of path to new directory. Makes directory in file system.
    #' @examples 
    #' makeDir("~/", "makeDir_test")
    #' @export
    
  # Concatenate to final path
  temp_dir_v <- file.path(base_dir_v, new_dir_v)
  # Add trailing slash, if absent
  if (substring(temp_dir_v, nchar(temp_dir_v)) != "/") {
    temp_dir_v <- paste0(temp_dir_v, "/")
  } # fi
  # Make if doesn't already exist
  if(dir.exists(temp_dir_v)){
    return(temp_dir_v)
  } else {
    dir.create(temp_dir_v)
    # Return string of path
    return(temp_dir_v)
  } # fi
} # makeDir
