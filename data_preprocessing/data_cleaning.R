# This is a script to find and deleting bouts in our timeseries of weather tower data that 
# have sensor or calibration errors. This is determined by repetitive inaccurate measurements.

all_dates <- list()
# Looping through each site and adding dates to an embedded list
# these were plotted as I went, and notes were taken on which need some 
# extra work
for (site in unique(flux$site)){
  calibration <- find_calibration(site=site,Date=flux[flux$site==site,"Date"],
                                  measure=flux[flux$site==site,"NEE"])
  if (length(calibration$dates) > 0){
    all_dates <- append(all_dates,list(calibration$dates))
  } else {
    all_dates <- append(all_dates,list(list("1900-01-01","1900-01-02")))
  }
}

# Assigning the site names as a key
names(all_dates) <- unique(flux$site)

# EXTRA EDITING
# These three sites needed to extend their point dropping to the start
all_dates$`US-AR1`[[1]][1] <- min(flux[flux$site=="US-AR1","Date"])
all_dates$`US-IB2`[[1]][1] <- min(flux[flux$site=="US-IB2","Date"])
all_dates$`US-Prr`[[1]][1] <- min(flux[flux$site=="US-Prr","Date"])

# These three sites shouldn't have anything dropped from them
all_dates$`US-Me2` <- list(list("1900-01-01","1900-01-02"))
all_dates$`US-WCr` <- list(list("1900-01-01","1900-01-02"))
all_dates$`US-Vcp` <- list(list("1900-01-01","1900-01-02"))

# For this site, the first date range is going to be saved in the data
all_dates$`US-Me3` <- all_dates$`US-Me3`[[2]]

# Some more specific alterations for certain sites
all_dates$`US-Tw1`[[1]][[2]] <- "2012-08-05"
all_dates$`US-Tw3`[[1]][[2]] <- "2013-05-27"
all_dates$`US-ARc` <- list(list(min(flux[flux$site=="US-ARc","Date"]),"2005-04-06"))
all_dates$`US-Sta` <- list(list(min(flux[flux$site=="US-Sta","Date"]),"2007-02-01"))
all_dates$`US-Blo` <- list(list("1997-01-01","2000-01-01"),list("2007-07-01","2008-01-01"))

# CHECKING EVERYTHING
for (i in 1:length(unique(flux$site))){
  site <- unique(flux$site)[i]
  data <- flux[flux$site==site,]
  to_drop <- rep(0,nrow(data))
  dates <- all_dates[[i]]
  
  for (j in 1:length(dates)){
    start_date <- unlist(dates[[j]])[1]
    end_date <- unlist(dates[[j]])[2]
    within_dates <- which(data$Date >= start_date & data$Date <= end_date)
    to_drop[within_dates] <- 1
  }
  to_drop <- as.factor(to_drop)
}

# Saving this list of dates for use in the random forest
save(all_dates,file="dropDates.R")

# Checking my work after the fact: looks great!
for (i in 1:length(unique(flux$site))){
  site <- unique(flux$site)[i]
  myplot <- ggplot(flux[flux$site==site,],aes(x=Date,y=NEE)) +
    geom_point() + ggtitle(site)
  print(myplot)
  readline(prompt = "Press [Enter] to continue...")
}

