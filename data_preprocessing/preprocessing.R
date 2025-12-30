# This script loads in the tower data (post calibration error cleaning), performs
# some preprocessing/cleaning, and applies a quantile regression approach to define
# anomalously high GPP (extreme sink) and anomalously high Reco (extreme source) days

# Loading packages
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(stats)
library(qgam)
library(zoo)

# DATA PREPROCESSING ###########################################################
# Loading in data
flux <- read.csv("flux_swc_after2015.csv")
head(flux)
colnames(flux)

# Changing date into a date class
flux$Date <- as.Date(flux$Date)

# Creating a numerical date
flux <- flux %>% 
  group_by(Year) %>% 
  mutate(Date_day = as.numeric(Date - min(Date) + 1))

# Remove sites with less than 15 years of data
site_years <- flux %>% group_by(site) %>% summarize(years = length(unique(Year)))
site_years <- data.frame(site_years)
included_sites <- site_years$site[site_years$years >= 12]
flux <- flux[flux$site %in% included_sites,]

# Deleting data that doesn't have SWC
flux %>% 
  group_by(site) %>% 
  summarize("Years"=length(unique(Year)),
            "Days"=length(Day),
            "SWC"=sum(is.na(SWC)),
            "TA"=sum(is.na(TA)),
            "P"=sum(is.na(P)),
            "VPD"=sum(is.na(VPD)),
            "SW"=sum(is.na(SW)))

# Creating a copy of flux that will be modified to hold the transition data
flux_transition <- flux

# Add the new columns that will be included
flux_transition$upper_quantile_GPP <- rep(NA,nrow(flux_transition))
flux_transition$upper_quantile_Reco <- rep(NA,nrow(flux_transition))
flux_transition$extreme_GPP <- rep(NA,nrow(flux_transition))
flux_transition$extreme_Reco <- rep(NA,nrow(flux_transition))

# Now we will use a transitioning quantile regression approach to define 
# daily values of GPP and Reco that are considered extreme
for (where in unique(flux$site)){
  
  data = flux[flux$site==where,]
  
  # Isolating the first and last five years of data
  start_date <- min(data$Date)
  year_4_start <- start_date + years(4)
  end_date <- max(data$Date)
  year_4_end <- end_date - years(4)
  
  # Find indices in those first and last five years
  in_first_5 <- (data$Date >= start_date) & (data$Date <= year_4_start)
  in_last_5 <- (data$Date >= year_4_end) & (data$Date <= end_date)
  
  # Assign data that belongs to first or last five years
  first_five <- data[in_first_5,]
  last_five <- data[in_last_5,]
  
  # Ordering by day of the year
  first_five <- first_five[order(first_five$Date_day),]
  last_five <- last_five[order(last_five$Date_day),]
  
  # Fitting quantile regression to first and last five data
  first_GPP_95th <- qgam(GPP ~ s(Date_day, k=6, bs="cc"), data = first_five, qu = 0.95)
  first_five$first_upper_GPP <- fitted(first_GPP_95th)
  
  first_Reco_95th <- qgam(Reco ~ s(Date_day, k=6,bs="cc"), data = first_five, qu = 0.95)
  first_five$first_upper_Reco <- fitted(first_Reco_95th)
  
  last_GPP_95th <- qgam(GPP ~ s(Date_day, k=6,bs="cc"), data = last_five, qu = 0.95)
  last_five$last_upper_GPP <- fitted(last_GPP_95th)
  
  last_Reco_95th <- qgam(Reco ~ s(Date_day, k=6,bs="cc"), data = last_five, qu = 0.95)
  last_five$last_upper_Reco <- fitted(last_Reco_95th)
  
  # Reorder by data
  last_five <- last_five[order(last_five$Date),]
  first_five <- first_five[order(first_five$Date),]
  
  # Left merging these first and last five quantile trends to the data by Date_day
  first <- unique(first_five[,c("Date_day","first_upper_GPP","first_upper_Reco")])
  last <- unique(last_five[,c("Date_day","last_upper_GPP","last_upper_Reco")])
  data <- left_join(data,first,by="Date_day")
  data <- left_join(data,last,by="Date_day")
  
  # Impute missing data
  if (sum(is.na(data$first_upper_GPP)) > 0){
    data$first_upper_GPP[which(is.na(data$first_upper_GPP))] <- impute_NA(data,"first_upper_GPP")
  }
  
  if (sum(is.na(data$first_upper_Reco)) > 0){
    data$first_upper_Reco[which(is.na(data$first_upper_Reco))] <- impute_NA(data,"first_upper_Reco")
  }
  
  if (sum(is.na(data$last_upper_GPP)) > 0){
    data$last_upper_GPP[which(is.na(data$last_upper_GPP))] <- impute_NA(data,"last_upper_GPP")
  }
  
  if (sum(is.na(data$last_upper_Reco)) > 0){
    data$last_upper_Reco[which(is.na(data$last_upper_Reco))] <- impute_NA(data,"last_upper_Reco")
  }
  
  # Calculate number of days in between first and last four years
  days_between <- seq(from=max(first_five$Date),to=min(last_five$Date),by="day")
  length_between <- length(days_between)
  
  # Use number of days between to calculate a weight for first_five and last_five
  weight <- seq(1,length_between) / length_between
  
  # Create dataframe and left merge into site data
  weight_data <- data.frame("Date"=days_between,"weight"=weight)
  data <- left_join(data,weight_data,by="Date")
  
  # Assign first and last five years weights of 1 and 0
  data$weight[data$Date %in% first_five$Date] <- 0
  data$weight[data$Date %in% last_five$Date] <- 1
  
  # Use the weights to calculate the GPP and Reco upper trendlines
  data$upper_quantile_GPP <- (1-data$weight)*data$first_upper_GPP + data$weight*data$last_upper_GPP
  data$upper_quantile_Reco <- (1-data$weight)*data$first_upper_Reco + data$weight*data$last_upper_Reco
  
  # defining extremes
  data$extreme_GPP <-ifelse(data$GPP > data$upper_quantile_GPP,1,0)
  data$extreme_Reco <- ifelse(data$Reco > data$upper_quantile_Reco,1,0)
  
  # Drop columns we don't need
  data <- data[,c(1:16,22:25)]
  
  # Assigning to dataset
  flux_transition[flux_transition$site==where,] <- data
  
}

# Write these extreme definitions to a dataframe and store as csv
write.csv(flux_transition,"transition_flux.csv")

# Below are visualizations to be performed across all sites to check the 
# validity of the quantile regressions fit and the defined extreme days.
# Everything looks good to go!
# CHECKING SITE FITTINGS #######################################################

for (where in unique(flux_transition$site)){
  
  data <- flux_transition[flux_transition$site==where,]
  
  plot(data$Date,data$GPP,main=paste(where,"GPP"),xlab="Date",ylab="GPP")
  lines(data$Date,data$upper_quantile_GPP,col="red")
  points(data$Date[data$extreme_GPP==1],data$GPP[data$extreme_GPP==1],pch=21,bg="green")
  
  readline("Press enter to continue")
}

# FITTING TRENDLINE ON ONE SITE EXAMPLE ########################################
# fitting first and last 5 years with quantile regression

# Starting with site NR1
where = "US-UMd"
data = flux[flux$site==where,]

# Dropping data before 1992
data = data[data$Year >= 1992,]
plot(data$Date_day,data$GPP,main="GPP yearly trend")
plot(data$Date, data$GPP,main="GPP timeseries")

# Isolating the first and last five years of data
start_date <- min(data$Date)
year_4_start <- start_date + years(4)
end_date <- max(data$Date)
year_4_end <- end_date - years(4)

# Adding to the timeseries
abline(v=start_date,col="red",lty="dashed")
abline(v=year_4_start,col="red",lty="dashed")
abline(v=end_date,col="red",lty="dashed")
abline(v=year_4_end,col="red",lty="dashed")

# Find indices in those first and last five years
in_first_5 <- (data$Date >= start_date) & (data$Date <= year_4_start)
in_last_5 <- (data$Date >= year_4_end) & (data$Date <= end_date)

# Assign data that belongs to first or last five years
first_five <- data[in_first_5,]
last_five <- data[in_last_5,]

# Plot these to verify: looks good!
points(first_five$Date,first_five$GPP,col="red")
points(last_five$Date,last_five$GPP,col="red")

# Ordering by day of the year
first_five <- first_five[order(first_five$Date_day),]
last_five <- last_five[order(last_five$Date_day),]

# Fitting quantile regression to first and last five data
first_GPP_95th <- qgam(GPP ~ s(Date_day, k=7, bs="cc"), data = first_five, qu = 0.95)
first_five$first_upper_GPP <- fitted(first_GPP_95th)

first_Reco_95th <- qgam(Reco ~ s(Date_day, k=7,bs="cc"), data = first_five, qu = 0.95)
first_five$first_upper_Reco <- fitted(first_Reco_95th)

last_GPP_95th <- qgam(GPP ~ s(Date_day, k=7,bs="cc"), data = last_five, qu = 0.95)
last_five$last_upper_GPP <- fitted(last_GPP_95th)

last_Reco_95th <- qgam(Reco ~ s(Date_day, k=7,bs="cc"), data = last_five, qu = 0.95)
last_five$last_upper_Reco <- fitted(last_Reco_95th)

# Plotting these to verify: looks good!
plot(first_five$Date_day,first_five$GPP)
lines(first_five$Date_day,first_five$first_upper_GPP,col="blue")

plot(last_five$Date_day,last_five$GPP)
lines(last_five$Date_day,last_five$last_upper_GPP,col="blue")

plot(first_five$Date_day,first_five$Reco)
lines(first_five$Date_day,first_five$first_upper_Reco,col="blue")

plot(last_five$Date_day,last_five$Reco)
lines(last_five$Date_day,last_five$last_upper_Reco,col="blue")

last_five <- last_five[order(last_five$Date),]
par(mfrow=c(2,1))
plot(last_five$Date,last_five$GPP,main="GPP",xlab="Date",ylab="GPP")
lines(last_five$Date,last_five$last_upper_GPP,col="blue")
plot(last_five$Date,last_five$Reco,main="Reco",xlab="Date",ylab="Reco")
lines(last_five$Date,last_five$last_upper_Reco,col="blue")
mtext("Last Five",outer=TRUE,line=-1)

first_five <- first_five[order(first_five$Date),]
par(mfrow=c(2,1))
plot(first_five$Date,first_five$GPP,main="GPP",xlab="Date",ylab="GPP")
lines(first_five$Date,first_five$first_upper_GPP,col="blue")
plot(first_five$Date,first_five$Reco,main="Reco",xlab="Date",ylab="Reco")
lines(first_five$Date,first_five$first_upper_Reco,col="blue")
mtext("First Five",outer=TRUE,line=-1)

# Left merging these first and last five quantile trends to the data by Date_day
first <- unique(first_five[,c("Date_day","first_upper_GPP","first_upper_Reco")])
last <- unique(last_five[,c("Date_day","last_upper_GPP","last_upper_Reco")])
data <- left_join(data,first,by="Date_day")
data <- left_join(data,last,by="Date_day")

# Impute NA values with a mean
data$first_upper_GPP[which(is.na(data$first_upper_GPP))] <- impute_NA(data,"first_upper_GPP")
data$first_upper_Reco[which(is.na(data$first_upper_Reco))] <- impute_NA(data,"first_upper_Reco")
data$last_upper_GPP[which(is.na(data$last_upper_GPP))] <- impute_NA(data,"last_upper_GPP")
data$last_upper_Reco[which(is.na(data$last_upper_Reco))] <- impute_NA(data,"last_upper_Reco")

# Plotting all of these on the same timeseries
plot(data$Date,data$GPP)
lines(first_five$Date,first_five$first_upper_GPP,col="red")
lines(last_five$Date,last_five$last_upper_GPP,col="red")

# Calculate number of days in between first and last four years
days_between <- seq(from=max(first_five$Date),to=min(last_five$Date),by="day")
length_between <- length(days_between)

# Use number of days between to calculate a weight for first_five and last_five
weight <- seq(1,length_between) / length_between

# Create dataframe and left merge into site data
weight_data <- data.frame("Date"=days_between,"weight"=weight)
data <- left_join(data,weight_data,by="Date")

# Assign first and last five years weights of 1 and 0
data$weight[data$Date %in% first_five$Date] <- 0
data$weight[data$Date %in% last_five$Date] <- 1

# Verify these weights
plot(data$Date,data$weight,xlab="Date",ylab="Weight of ending trendline",main="Change in weight of ending trendline over timeseries")

# Use the weights to calculate the GPP and Reco upper trendlines
data$upper_quantile_GPP <- (1-data$weight)*data$first_upper_GPP + data$weight*data$last_upper_GPP
data$upper_quantile_Reco <- (1-data$weight)*data$first_upper_Reco + data$weight*data$last_upper_Reco

# Verifying this timeseries: looks good!
plot(data$Date,data$GPP)
lines(data$Date,data$upper_quantile_GPP,col="red")

plot(data$Date,data$Reco)
lines(data$Date,data$upper_quantile_Reco,col="red")

# defining extremes
data$extreme_GPP <-ifelse(data$GPP > data$upper_quantile_GPP,1,0)
data$extreme_Reco <- ifelse(data$Reco > data$upper_quantile_Reco,1,0)

# verifying these extremes
plot(data$Date,data$GPP,main="GPP")
lines(data$Date,data$upper_quantile_GPP,col="red")
points(data$Date[data$extreme_GPP==1],data$GPP[data$extreme_GPP==1],pch=21,bg="green")

plot(data$Date,data$Reco,main="Reco")
lines(data$Date,data$upper_quantile_Reco,col="red")
points(data$Date[data$extreme_Reco==1],data$Reco[data$extreme_Reco==1],pch=21,bg="green")




