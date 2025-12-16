# winning BART model submitted via kaggle notebook

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
train <- vroom("/kaggle/input/bike-sharing-demand/train.csv")
test <- vroom("/kaggle/input/bike-sharing-demand/test.csv")


### HW BART ------------------------------------------------
train_clean <- train %>%
  select(-casual, -registered) %>% # Remove columns as per HW
  mutate(count = log(count))        # Log-transform target variable

bike_recipe <- recipe(count~., data=train_clean) %>% 
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
  step_zv(all_predictors()) %>%
  step_rm(datetime) %>%
  step_dummy(all_nominal_predictors()) %>% 
  step_normalize(all_numeric_predictors())

# bake(prep(bike_recipe), new_data=train_clean) %>%
#   summary(.)

preg_model <- bart(trees = tune()) %>%
  set_engine("dbarts") %>%
  set_mode("regression")

preg_wf <- workflow() %>%
  add_recipe(bike_recipe) %>%
  add_model(preg_model) 

prepped <- prep(bike_recipe)
# num_predictors <- ncol(bake(prepped, new_data = NULL)) - 1

grid_of_tuning_params <- grid_regular(trees(),
                                      levels = 5)

folds <- vfold_cv(train_clean, v = 10, repeats = 1)

CV_results <- preg_wf %>%
  tune_grid(resamples=folds,
            grid=grid_of_tuning_params,
            metrics = metric_set(rmse)) #change to mae 

bestTune <- CV_results |>
  select_best(metric="rmse")

final_wf <-preg_wf |>
  finalize_workflow(bestTune) |>
  fit(data=train_clean)

bike_preds <- final_wf %>%
  predict(new_data=test) %>%
  mutate(count = exp(.pred))

kaggle_submission <- bike_preds %>%
  bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
  select(datetime, count) %>%               # Column order
  mutate(count = pmax(0, count)) %>%
  mutate(datetime=as.character(format(datetime)))

vroom_write(kaggle_submission, "predictions.csv", delim=",")