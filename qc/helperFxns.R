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
