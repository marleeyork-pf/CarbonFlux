# This functions imputes missing weather data with the mean value of surrounding 
# 2 or 4 days. If there is not sufficient surrounding data, it is replaced with NA.

# Inputs:
  # data: dataframe including the variable we want to impute
  # var: the variable name we are interesting in performing imputation for

# Outputs:
  # imputed: returns a list of the imputed values

impute_NA <- function(data, var) {
  miss_idx <- which(is.na(data[[var]]))
  n_missing <- length(miss_idx)
  
  # containers
  prev  <- fut  <- prev2 <- fut2 <- rep(NA_real_, n_missing)
  
  for (i in seq_along(miss_idx)) {
    k <- miss_idx[i]
    
    if (k - 1 >= 1)           prev[i]  <- data[[var]][k - 1]
    if (k + 1 <= nrow(data))  fut[i]   <- data[[var]][k + 1]
    if (k - 2 >= 1)           prev2[i] <- data[[var]][k - 2]
    if (k + 2 <= nrow(data))  fut2[i]  <- data[[var]][k + 2]
  }
  
  neigh <- cbind(prev, fut, prev2, fut2)
  
  ## take the mean of the available neighbours; NA if none are available
  imputed <- rowMeans(neigh, na.rm = TRUE)
  
  return(imputed)
}

