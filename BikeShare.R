library(tidyverse)
library(tidymodels)
library(vroom)
library(dplyr)
library(DataExplorer)
library(patchwork)
library(lubridate)  # for hour extraction

# Load data
train <- vroom("C:/Users/Jenna/OneDrive/Desktop/Statistics/Stat 348/BikeShare/train.csv")
test <- vroom("C:/Users/Jenna/OneDrive/Desktop/Statistics/Stat 348/BikeShare/test.csv")

# Old factor conversions (commented out)
# train$weather <- as.factor(train$weather)
# train$season <- as.factor(train$season)
# train$holiday <- as.factor(train$holiday)
# train$workingday <- as.factor(train$workingday)

# Old exploratory plots (commented out)
# glimpse(train)
# DataExplorer::plot_correlation(train)
# DataExplorer::plot_intro(train)
# DataExplorer::plot_bar(train)
# DataExplorer::plot_missing(train)
# GGally::ggpairs(train)
# DataExplorer::plot_histogram(train)

# Old visualizations (commented out)
# p1 <- ggplot(train, aes(x=humidity)) + geom_histogram(bins=30, fill="skyblue")
# p2 <- ggplot(data= train)+ geom_bar(aes(x=weather, fill=season))
# p3 <- ggplot(data=train)+geom_point(aes(x=atemp, y=temp))
# p4 <- ggplot(data=train)+geom_point(aes(x=casual, y=count))
# (p1 + p2) / (p3 + p4)

# HW Step 1: Data Cleaning
# train_clean <- train %>%
#   select(-casual, -registered) %>% # Remove columns as per HW
#   mutate(count = log(count))        # Log-transform target variable

# # HW Step 2: Feature Engineering
# bike_recipe <- recipe(count ~ ., data = train_clean) %>%
#   step_mutate(weather = ifelse(weather == 4, 3, weather)) %>% # Recode weather 4->3
#   # step_mutate(weather = factor(weather)) %>%
#   # step_mutate(holiday = factor(holiday)) %>%
#   # step_mutate(workingday = factor(workingday)) %>%
#   # step_mutate(season = factor(season)) %>%  
#   # step_mutate(hour = hour(datetime)) %>%
#   step_time(datetime, features="hour") %>%
#   step_date(datetime, features="month") %>%
#   step_date(datetime, features = "doy") %>%
#   step_rm(datetime) %>%
#   step_normalize(all_numeric_predictors()) %>%
#   step_dummy(all_nominal_predictors()) %>%
#   step_zv(all_predictors()) # Remove zero-variance predictors
# 
# # Prepare and bake recipe (optional check)
# # prepped_recipe <- prep(bike_recipe)
# # baked_data <- bake(prepped_recipe, new_data = train_clean)
# # head(baked_data, 5)  # Show first 5 rows for HW
# 
# # first penalty=0.01, mixture=0.01
# # second penalty=0.5, mixture=0.05
# # 3 penalty=0.1, mixture=0.1
# # 4 penalty=0.5, mixture=0.1
# 
# ## new penalized regression ----------------------------------
# preg_model <- linear_reg(penalty=0.1, mixture=0.1) %>%
#   set_engine("glmnet") # Function to fit in R11
# preg_wf <- workflow() %>%
#   add_recipe(bike_recipe) %>%
#   add_model(preg_model) %>%
#   fit(data=train_clean)
# bike_preds <- predict(preg_wf, new_data=test) %>%
#   mutate(count = exp(.pred))
# 
# kaggle_submission <- bike_preds %>%
#   bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
#   select(datetime, count) %>%               # Column order
#   mutate(count = pmax(0, count)) %>%
#   mutate(datetime=as.character(format(datetime)))
# 
# vroom_write(kaggle_submission, "LinearPreds_v2.csv", delim = ",")


## # HW Step 3: Linear Regression Workflow ------------------
# bike_workflow <- workflow() %>%
#   add_recipe(bike_recipe) %>%
#   add_model(
#     linear_reg() %>% 
#       set_engine("lm") %>% 
#       set_mode("regression")
#   )
# 
# bike_fit <- bike_workflow %>% fit(data = train_clean)

# # HW Step 4: Predict on Test
# bike_preds <- predict(bike_fit, new_data = test) %>%
#   mutate(count = exp(.pred))  # Back-transform log(count)

# kaggle_submission <- bike_preds %>%
#   bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
#   select(datetime, count) %>%               # Column order
#   mutate(count = pmax(0, count)) %>%
#   mutate(datetime=as.character(format(datetime)))
# 
# vroom_write(kaggle_submission, "LinearPreds_v2.csv", delim = ",")

########## Old linear model approach (commented out)
# my_linear_model <- linear_reg() |> 
#   set_engine("lm") |>
#   set_mode("regression") |>
#   fit(formula=count ~. -datetime , data = newtrain)
# bike_predictions <- predict(my_linear_model, new_data=test)
# bike_predictions
# kaggle_submission <- bike_predictions %>%
#   bind_cols(., test) %>% 
#   select(datetime, .pred) %>%
#   rename(count=.pred) %>%
#   mutate(count=pmax(0, count)) %>%
#   mutate(datetime=as.character(format(datetime)))
# vroom_write(x=kaggle_submission, file="./LinearPreds.csv", delim = ",")

##### Tuning 9_17 -----------------------------------------------------------

# HW Step 2: Feature Engineering
# bike_recipe <- recipe(count ~ ., data = train_clean) %>%
#   step_mutate(weather = ifelse(weather == 4, 3, weather)) %>% # Recode weather 4->3
#   step_mutate(weather = factor(weather)) %>%
#   step_mutate(holiday = factor(holiday)) %>%
#   step_mutate(workingday = factor(workingday)) %>%
#   step_mutate(season = factor(season)) %>%
#   step_mutate(hour = hour(datetime)) %>%
#   # step_time(datetime, features="hour") %>%
#   step_mutate(hour_sin = sin(2 * pi * hour / 24),
#               hour_cos = cos(2 * pi * hour / 24)) %>%
#   step_date(datetime, features="month") %>%
#   step_date(datetime, features = "doy") %>%
#   step_rm(datetime) %>%
#   step_normalize(all_numeric_predictors()) %>%
#   step_dummy(all_nominal_predictors()) %>%
#   step_zv(all_predictors()) # Remove zero-variance predictors
# 
# preg_model <- linear_reg(penalty=tune(), mixture=tune()) %>%
#   set_engine("glmnet") # Function to fit in R11
# preg_wf <- workflow() %>%
#   add_recipe(bike_recipe) %>%
#   add_model(preg_model) 
# 
# grid_of_tuning_params <- grid_regular(penalty(),
#                                       mixture(),
#                                       levels =5)
# folds <- vfold_cv(train_clean, v = 10, repeats = 1)
# 
# CV_results <- preg_wf %>%
#   tune_grid(resamples=folds,
#             grid=grid_of_tuning_params,
#             metrics = metric_set(rmse)) #change to mae 
# 
# collect_metrics(CV_results) %>%
#   filter(.metric=="rmse") %>%
#   ggplot(data=., aes(x=penalty, y=mean, color=factor(mixture))) + 
#   geom_line()
# 
# bestTune <- CV_results |>
#   select_best(metric="rmse")
# 
# final_wf <-preg_wf |>
#   finalize_workflow(bestTune) |>
#   fit(data=train_clean)
# 
# # final_wf |> 
# #   predict(new_data = test)%>%
# #     mutate(count = exp(.pred))
# 
# bike_preds <- final_wf %>%
#   predict(new_data=test) %>%
#   mutate(count = exp(.pred))
# 
# kaggle_submission <- bike_preds %>%
#   bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
#   select(datetime, count) %>%               # Column order
#   mutate(count = pmax(0, count)) %>%
#   mutate(datetime=as.character(format(datetime)))
# 
# vroom_write(kaggle_submission, "LinearPreds_v3.csv", delim = ",")

### HW REGRESSION TREES------------------------------------------------
# train_clean <- train %>%
#   select(-casual, -registered) %>% # Remove columns as per HW
#   mutate(count = log(count))        # Log-transform target variable

# bike_recipe <- recipe(count ~ ., data = train_clean) %>%
#   step_mutate(weather = ifelse(weather == 4, 3, weather)) %>% # Recode weather 4->3
#   step_mutate(weather = factor(weather)) %>%
#   step_mutate(holiday = factor(holiday)) %>%
#   step_mutate(workingday = factor(workingday)) %>%
#   step_mutate(season = factor(season)) %>%
#   step_mutate(hour = hour(datetime)) %>%
#   # step_time(datetime, features="hour") %>%
#   step_mutate(hour_sin = sin(2 * pi * hour / 24),
#               hour_cos = cos(2 * pi * hour / 24)) %>%
#   step_date(datetime, features="month") %>%
#   step_date(datetime, features = "doy") %>%
#   step_rm(datetime) %>%
#   step_normalize(all_numeric_predictors()) %>%
#   step_dummy(all_nominal_predictors()) %>%
#   step_zv(all_predictors()) # Remove zero-variance predictors
# 
# # preg_model <- linear_reg(penalty=tune(), mixture=tune()) %>%
# #   set_engine("glmnet") # Function to fit in R11
# # preg_wf <- workflow() %>%
# #   add_recipe(bike_recipe) %>%
# #   add_model(preg_model) 
# 
# preg_model <- decision_tree(tree_depth=tune(), 
#                             cost_complexity=tune(), 
#                             min_n=tune()) %>%
#   set_engine("rpart") %>% # Function to fit in R11
#   set_mode("regression")
# 
# preg_wf <- workflow() %>%
#   add_recipe(bike_recipe) %>%
#   add_model(preg_model) 
# 
# grid_of_tuning_params <- grid_regular(tree_depth(),
#                                       cost_complexity(),
#                                       min_n(),
#                                       levels =5)
# folds <- vfold_cv(train_clean, v = 5, repeats = 1)
# 
# CV_results <- preg_wf %>%
#   tune_grid(resamples=folds,
#             grid=grid_of_tuning_params,
#             metrics = metric_set(rmse)) #change to mae 
# 
# # collect_metrics(CV_results) %>%
# #   filter(.metric=="rmse") %>%
# #   ggplot(data=., aes(x=penalty, y=mean, color=factor(mixture))) + 
# #   geom_line()
# 
# bestTune <- CV_results |>
#   select_best(metric="rmse")
# 
# final_wf <-preg_wf |>
#   finalize_workflow(bestTune) |>
#   fit(data=train_clean)
# 
# # final_wf |> 
# #   predict(new_data = test)%>%
# #     mutate(count = exp(.pred))
# 
# bike_preds <- final_wf %>%
#   predict(new_data=test) %>%
#   mutate(count = exp(.pred))
# 
# kaggle_submission <- bike_preds %>%
#   bind_cols(test %>% select(datetime)) %>%  # Keep original test datetime
#   select(datetime, count) %>%               # Column order
#   mutate(count = pmax(0, count)) %>%
#   mutate(datetime=as.character(format(datetime)))
# 
# vroom_write(kaggle_submission, "LinearPreds_v4.csv", delim = ",")

### HW random forests ------------------------------------------------
train_clean <- train %>%
  select(-casual, -registered) %>% # Remove columns as per HW
  mutate(count = log(count))        # Log-transform target variable

bike_recipe <- recipe(count ~ ., data = train_clean) %>%
  step_mutate(weather = ifelse(weather == 4, 3, weather)) %>% # Recode weather 4->3
  step_mutate(weather = factor(weather)) %>%
  step_mutate(holiday = factor(holiday)) %>%
  step_mutate(workingday = factor(workingday)) %>%
  step_mutate(season = factor(season)) %>%
  step_mutate(hour = hour(datetime)) %>%
  step_mutate(hour_sin = sin(2 * pi * hour / 24),
              hour_cos = cos(2 * pi * hour / 24)) %>%
  step_date(datetime, features="month") %>%
  step_date(datetime, features = "doy") %>%
  step_rm(datetime) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_zv(all_predictors()) # Remove zero-variance predictors

# bake(prep(bike_recipe), new_data=train_clean) %>%
#   summary(.)

preg_model <- rand_forest(mtry = tune(), 
                          min_n = tune(),
                          trees=500) %>%
  set_engine("ranger") %>%
  set_mode("regression")

preg_wf <- workflow() %>%
  add_recipe(bike_recipe) %>%
  add_model(preg_model) 

prepped <- prep(bike_recipe)
num_predictors <- ncol(bake(prepped, new_data = NULL)) - 1

grid_of_tuning_params <- grid_regular(mtry(range = c(1, num_predictors)),
                                      min_n(),
                                      levels = 5)

# grid_of_tuning_params <- grid_regular(mtry(range=c(1, ncol(train_clean)-1)),
#                                       min_n(),
#                                       levels =5)

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

vroom_write(kaggle_submission, "LinearPreds_v4.csv", delim = ",")
