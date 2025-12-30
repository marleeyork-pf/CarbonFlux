# This function is designed to identify bouts of continuous identical measurements
# over a series of days from weather towers, as this indicates calibration or sensor
# errors. These calibration bouts are identified and returned to be removed.

# Inputs:
  # site: The site name for the weather tower
  # Date: The timeseries column of dates
  # measure: The column of the measure we are interesting in cleaning (associated with the dates column)

# Outputs:
  # drop_dates: A list of dates that need to removed from the sites data due
  #             to calibration/sensor errors

find_calibration <- function(site,Date,measure){
  start <- list()
  cont <- list()
  j <- 1
  # first, looping through each result and finding repeats
  for (i in 8:length(measure)){
    prev <- measure[(i-7):i]
    count <- sum(prev==measure[i])
    if (count>1){
      start[j] <- i-7
      j = j+1
    }
  }
  # find difference between each point, 1 means its continuous with its previous point
  continuity <- diff(unlist(start))
  
  # intitlize a list of groups of continuous points
  continuous_groups <- list(list(),list(),list(),list(),list(),list(),list(),list(),list(),list(),
                            list(),list(),list(),list(),list(),list(),list(),list(),list(),list(),
                            list(),list(),list(),list(),list(),list(),list(),list(),list(),list())
  
  # iterate through points, adding to a group if its a 1 and switching groups
  # when the pattern of 1 is broken
  if (length(continuity) > 0){
    j = 1
    k = 1
    for (i in 1:length(continuity)){
      if (continuity[i]==1){
        continuous_groups[[k]][j] <- unlist(start)[i]
        j <- j+1
      } else {
        j <- 0
        k <- k+1
      }
    }
    
    # list through each group and pull out beginning and ending index
    # assign the dates associated with these indexes to lists
    group_date <- list(list(),list(),list(),list(),list(),list(),list(),list(),
                       list(),list(),list(),list(),list(),list(),list(),list(),
                       list(),list(),list(),list(),list(),list(),list(),list())
    j <- 1
    for (i in 1:30){
      group <- unlist(continuous_groups[[i]])
      if (length(group) > 20) {
        group_date[[j]][1] <- Date[min(group)]
        group_date[[j]][2] <- Date[max(group) + 8]
        j = j+1
      }
    }
    
    # drop empty lists
    group_date <- Filter(function(x) length(x) > 0, group_date)
    
    
    # set up indicator variable if the dates are within the drop range or not
    to_drop <- rep(0,length(measure))
    
    # loop through each date range and print it out
    # identify variables in that range
    if (length(group_date) > 0){
      for (i in 1:length(group_date)){
        print(unlist(group_date[[i]]))
        start_date <- group_date[[i]][1]
        end_date <- group_date[[i]][2]
        within_date <- which(Date >= start_date & Date <= end_date)
        to_drop[within_date] <- 1
      }
    }
    to_drop <- as.factor(to_drop)
    
    
    # plot NEE along GPP, with the dropping dates red
    if (length(group_date)>0){
      myplot <- ggplot(mapping=aes(x=Date,y=measure,col=to_drop)) + geom_point() + 
        ggtitle(site) + scale_color_manual(values=c("0"="cadetblue3","1"="brown2"))
    } else {
      myplot <- ggplot(mapping=aes(x=Date,y=measure)) + geom_point(col="cadetblue3") +
        ggtitle(site)
    }
    
  } else {
    myplot <- ggplot(mapping=aes(x=Date,y=measure)) + geom_point(col="cadetblue3") +
      ggtitle(site)
    group_date <- list()
  }
  

  
  # return
  return(list(plot = myplot,dates = group_date))
}








