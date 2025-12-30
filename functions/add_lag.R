# This function was created to calculated a lagged average of timeseries data
# over a provided number of antecedent days

# Inputs:
  # df: dataframe including (at least) a dates column, and the variable column of interest
  # var: name of the variable we are interested in calculating the lag of
  # days: number of days we want our lag to cover

# Output:
  # df_final: dataframe with column added with the lagged variable

add_lag <- function(df,var,days){
  df_lag <- df
  df_lag$Date <- as.Date(df_lag$Date)
  
  # Initialize empty list
  df_lag_list <- list()
  
  # Loop through each site
  for (site in unique(df_lag$site)){
    print(site)
    dat <- df_lag[df_lag$site==site,]
    
    # Create mean variable and sd variable (if applicable)
    lag_var_name <- paste0(var,"_",days)
    print(lag_var_name)
    dat[,lag_var_name] <- rep(NA,nrow(dat))
    if (days > 1){
      # This is the name for the sd variable
      lag_sd_name <- paste0(var,"_sd_",days)
      # Initializing its values
      dat[,lag_sd_name] <- rep(NA,nrow(dat))
    }
    
    # Loop through each entry in the site dataset
    for (i in 1:nrow(dat)){
      # Find the lag date range for that entry
      end_date <- dat$Date[i] - 1
      start_date <- dat$Date[i] - days
      print(paste("End date:",end_date,"start date:",start_date))
      date_range <- seq(start_date,end_date,by="day")
      # Find entries in dat that fall in this range
      in_lag <- dat[dat$Date %in% date_range,]
      # If theres <.7 of the data, assign as NA
      count <- nrow(in_lag)
      if ((count/days) < .7){
        dat[i,lag_var_name] <- NA
        if (days>1){
          dat[i,lag_sd_name] <- NA
        }
      }
      # If not, calculate mean of in_lag columns and assign
      else {
        dat[i,lag_var_name] <- colMeans(in_lag[,var])
        print(dat[i,lag_var_name])
        # If more than one day, calculate and add sd
        if (days > 1){
          dat[i,lag_sd_name] <- apply(in_lag[,var],2,sd)
        }
      }
    }
    # Add dat to list
    df_lag_list <- append(df_lag_list,list(dat))
  }
  df_final <- do.call(rbind,df_lag_list)
  return(df_final)
}