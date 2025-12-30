# This is an example R script for HPC submission to fit a random forest classifier
################################################################################
# Model: Full year strong gpp sink with climatic data included

### Bring in necessary packages
setwd("/scratch/my464/cflux")

# pacman::p_load("randomForestSRC")
library(randomForestSRC)
################################################################################

# Read in files
load("./data/bindat.all.R")

# Identify variables wanted as input to classify for extreme GPP
vnamessink <- colnames(bindat.all)[c(8:11,13:19,21:48,50)]

# Run model to classify for extreme GPP using the specified inputs
set.seed(76786+12366)

sink.all <- imbalanced.rfsrc(sink ~.,data=bindat.all[vnamessink], na.action="na.omit",
                             method="rfq",importance="permute",block.size=1,
                             perf.type="misclass")

# Save model results
save(sink_clim_results,file="./results_code3/sink_clim_results.RData")
saveRDS(sink_clim_results,file="./results_code3/sink_clim_results.rds")
save(sink_clim_results,file="./results_code3/sink_clim_results.R")