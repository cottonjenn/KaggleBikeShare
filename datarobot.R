library(tidyverse)
library(tidymodels)
library(vroom)
library(dplyr)
library(DataExplorer)
# library(patchwork)
library(lubridate)  # for hour extraction
library(bonsai)
library(lightgbm)

# Load data
# train <- vroom("C:/Users/Jenna/OneDrive/Desktop/Statistics/Stat 348/BikeShare/train.csv")
test <- vroom("C:/Users/Jenna/OneDrive/Desktop/Statistics/Stat 348/BikeShare/test.csv")

# test_clean <- test %>%
#   # select(-registered) %>% # Remove columns as per HW
#   mutate(count = log(count))        # Log-transform target variable

bike_recipe <- recipe(~., data=test) %>% 
  step_mutate(weather = ifelse(weather == 4, 3, weather)) %>%
  step_mutate(weather = as.factor(weather)) %>%
  step_date(datetime, features = "dow") %>%
  step_time(datetime, features = c("hour")) %>%
  step_date(datetime, features = c("month")) %>%
  step_date(datetime, features = c("year")) %>%
  step_mutate(datetime_dow = as.factor(datetime_dow)) %>%
  step_mutate(datetime_hour = as.factor(datetime_hour)) %>%
  step_mutate(datetime_month = as.factor(datetime_month)) %>%
  step_mutate(datetime_year = as.factor(datetime_year)) %>%
  step_interact(~datetime_hour:workingday) %>%
  step_interact(~datetime_hour:datetime_dow) %>%
  step_mutate(season = as.factor(season)) %>%
  # step_corr(allnumeric_predictors())%>%
  step_zv(all_predictors()) %>%
  step_rm(datetime) %>%
  step_dummy(all_nominal_predictors()) %>% 
  step_normalize(all_numeric_predictors())

new_data <- bake(prep(bike_recipe), new_data=test)
vroom_write(new_data, "new_data.csv", delim = ",")






preds <- vroom("C:/Users/Jenna/Downloads/results.csv")
colnames(preds)[1] <- "count"

kaggle_submission <- preds %>%
  bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
  select(datetime, count) %>%               # Column order
  mutate(count = pmax(0, count)) %>%
  mutate(datetime=as.character(format(datetime)))%>%
  mutate(count = exp(count))

vroom_write(kaggle_submission, "datarobot.csv", delim = ",")
