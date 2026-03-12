library(ggplot2)
library(dplyr)
library(reshape2)

# params
thresh = 543 # dPixel>thresh -> "1" (moved) ## Example value; calibrate for each dataset if acquisition conditions differ
bout.thresh = 12 # in frame ## Example value; calibrate for each dataset if acquisition conditions differ
nframe = 56517
nhour = 18
srate = nframe / nhour
jet.colors = colorRampPalette(c("darkblue", "blue", "deepskyblue3", "mediumseagreen", "orange", "yellow", "lemonchiffon"))
ncore = detectCores()[1] - 1