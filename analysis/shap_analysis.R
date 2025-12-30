# This is the pipeline used to perform SHAP analysis on all variables for
# both extreme sink and source random forest

# Loading necessary packages
install.packages("doParallel")
install.packages("foreach")
library(doParallel)
library(foreach)
library(xgboost)
library(iml)
library(ggplot2)
library(randomForestSRC)
library(tidyverse)
library(xgboost)
library(caret)
library(parallel)
suppressPackageStartupMessages({
  library(tidyverse)
  library(cowplot)
  theme_set(theme_cowplot())
  library(xgboost)
  library(ggbeeswarm)
})
options(repr.plot.width=15,repr.plot.height=9)
data(boston, package='pdp')
set.seed(859)

# loading data
bindat_transitino <- read.csv("./data/bindat_transition.csv")

# loading a random forest
load("./model_results/transition_sink_results.R")

# Isolate training data
vnamessource <- colnames(bindat_common)[c(3:7,16:50,53)]
train_data <- bindat_common[vnamessource]
train_data$extreme_GPP <- as.factor(train_data$extreme_GPP)
train_data <- na.omit(train_data)

# Sample while maintaining distribution of a categorical variable (e.g., 'category_column')
X_sample <- train_data %>%
  group_by(extreme_GPP) %>%
  sample_frac(0.1)  # Take 10% from each category

X_sample <- data.frame(X_sample)
X_sample <- data.frame(select(X_sample,-extreme_GPP))

X = data.frame(select(train_data, -extreme_GPP))

# Compute SHAP values efficiently
shap_values <- fastshap::explain(
  object = common_sink_results,
  X = X_sample[1:3, ,drop=FALSE],
  nsim = 10, 
  pred_wrapper = function(model, newdata) {
    predict_model <- predict(model, newdata)
    predict_model$predicted[,2]
  },
  approx = TRUE
)
# Save SHAP values
saveRDS(shap_values, file = "shap_values_sampled.rds")
readRDS("shap_values_sampled.rds")

shap_values_df <- data.frame(shap_values)
View(shap_values_df)

### Organizing shap values into dataframe for analysis

# Add observation identification
shap_values_df$id <- 1:nrow(shap_values_df)

# Pivot the data frame longer
shap_values_df <- pivot_longer(shap_values_df,names_to="var",values_to="shap",-id)
shap_values_df <- data.frame(shap_values_df)

## Pivot the variable values longer

# Add id variable
X <- X_sample[1:3,]
X$id <- 1:nrow(X)

# Pivot longer
X <- pivot_longer(X,names_to="var",values_to="value",-id)
X <- data.frame(X)

# Inner join the shap and observation values
df <- inner_join(shap_values_df,X,by=c("id","var"))

### Creating plots
# Shap value for a given observation
filter(df, id==1) %>%
  ggplot(aes(x=shap, y=fct_reorder(paste0(var,'=',value),shap), fill=factor(sign(shap)))) +
  geom_col() + guides(fill='none') + 
  labs(y="", title="shap values for X[1,]")

# Mean absolute shap for all values
group_by(df, var) %>% 
  summarize(mean=mean(abs(shap))) %>%
  ggplot(aes(x=mean, y=fct_reorder(var, mean))) + 
  geom_col() +
  labs(x='mean(|shap value|)', title='mean absolute shap for all samples', y="")


# distribution of shap vaues for all samples
df %>%   
  group_by(var) %>% 
  filter(var %in% c("P_30","SW","SWC_30","SW_365","SW_sd_30")) %>% 
  mutate(nv=scale(value)) %>%
  ggplot(aes(x=shap, y=var, color=nv)) +
  geom_quasirandom(groupOnX = FALSE,dodge.width = 0.3) +
  scale_color_viridis_c(option = 'H', limits=c(-3, 3), oob=scales::oob_squish) +
  labs(title='distribution of shap values for all samples', y='',color='z-scaled values')

df %>%   
  group_by(var) %>% 
  filter(var %in% c("P_30","SW","SWC_30","SW_365","SW_sd_30")) %>% 
  mutate(nv=scale(value)) %>%
  ggplot(aes(x=shap, y=var, color=nv)) +
  geom_point() +
  scale_color_viridis_c(option = 'H', limits=c(-3, 3), oob=scales::oob_squish) +
  labs(title='distribution of shap values for all samples', y='',color='z-scaled values')