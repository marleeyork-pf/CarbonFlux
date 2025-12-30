# This function is used to collect a sample of n size with a uniform distribution
# of some environmental variable. The purpose of this function is to collect
# uniform samples of environmental variables to perform SHAP analysis on.

# Inputs:
  # df: dataframe of all tower station data
  # column_name: the name of the column that we want to be uniformly distributed 
  #              in our sample
  # n_bins: a hyperparameter when estimating a uniform density
  # n_samples: sample size

# Output:
  # result: dataframe of sample of n_samples size with uniformly distributed column_name

sample_to_uniform_distribution <- function(df, column_name, n_bins = 10, n_samples = NULL) {
  if(is.null(n_samples)) n_samples <- nrow(df)
  
  # Make sure the column exists
  if(!column_name %in% names(df)) {
    stop(paste("Column", column_name, "not found in dataframe"))
  }
  
  # Get the column values
  values <- df[[column_name]]
  
  # Create evenly spaced percentiles for bins
  percentiles <- seq(0, 1, length.out = n_bins + 1)
  breaks <- quantile(values, probs = percentiles, type = 1)
  
  # Get unique break values and their last occurrences
  unique_breaks <- unique(breaks)
  unique_indices <- sapply(unique_breaks, function(x) max(which(breaks == x)))
  
  # Sort the unique indices
  unique_indices <- sort(unique_indices)
  
  # Adjust the breaks to keep only the last occurrence of repeated values
  adjusted_breaks <- breaks[unique_indices]
  actual_bins <- length(adjusted_breaks) - 1
  
  if(actual_bins < n_bins) {
    message(paste("Due to repeated values, using", actual_bins, "effective bins instead of", n_bins))
  }
  
  # Create empty dataframe to store results
  result <- data.frame()
  
  # Calculate how many samples to take from each bin
  samples_per_bin <- floor(n_samples / actual_bins)
  extra_samples <- n_samples - (samples_per_bin * actual_bins)
  
  # Sample from each effective bin
  for(i in 1:actual_bins) {
    bin_samples <- samples_per_bin
    if(i <= extra_samples) bin_samples <- bin_samples + 1
    
    # Get indices for this bin
    bin_min <- adjusted_breaks[i]
    bin_max <- adjusted_breaks[i+1]
    
    if(i == actual_bins) {
      # Include the maximum value in the last bin
      bin_indices <- which(values >= bin_min & values <= bin_max)
    } else {
      bin_indices <- which(values >= bin_min & values < bin_max)
    }
    
    # Sample from this bin
    if(length(bin_indices) > 0) {
      bin_sample_indices <- sample(bin_indices, 
                                   size = min(bin_samples, length(bin_indices)), 
                                   replace = (bin_samples > length(bin_indices)))
      
      # Add to result
      result <- rbind(result, df[bin_sample_indices, ])
    }
  }
  
  return(result)
}
