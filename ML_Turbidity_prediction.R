
## Code for machine learning-based turbidity prediction

# Required libraries
library(caret)
library(randomForest)
library(dplyr)
library(tibble)
library(xgboost)
library(dplyr)
library(ggplot2)

# Dataframe import; turb_mean is the response variable, all other variables serve as predictors

data <- read.csv("/path/dataframe.csv",row.names = 1)


## Random Forest feature and parameter optimization; turb_mean is the response variable

# Define the run_replication function
run_replication <- function(data, train_frac = 0.75, sizes = c(1:17), ntree_values = c(100, 500, 1000)) {  # train/test split can be changed here
  # Split the data into training and testing sets
  trainIndex <- createDataPartition(data$turb_mean, p = train_frac, list = FALSE, times = 1)
  data_train <- data[trainIndex, ]
  data_test <- data[-trainIndex, ]
  
  # Perform Recursive Feature Elimination (RFE)
  control_rf <- rfeControl(functions = rfFuncs, method = "cv", number = 5)
  results_rf <- rfe(data_train[, -which(names(data_train) == "turb_mean")], 
                    data_train$turb_mean, 
                    sizes = sizes, 
                    rfeControl = control_rf)
  
  # Get the selected variables
  selected_vars_rf <- results_rf$optVariables
  formula_rf <- as.formula(paste("turb_mean ~", paste(selected_vars_rf, collapse = "+")))
  
  # Hyperparameter tuning for Random Forest
  control_rf <- trainControl(method = "cv", number = 5)
  
  # Adjust mtry values based on the number of selected variables
  num_predictors <- length(selected_vars_rf)
  mtry_values <- pmin(c(4, 6, 8), num_predictors)
  tuneGrid_rf <- expand.grid(mtry = mtry_values)
  
  # Create an empty list to store models
  models_rf <- list()
  
  # Iterate over the ntree values
  for (ntree in ntree_values) {
    set.seed(123)  #For reproducibility
    model_rf <- train(
      formula_rf, 
      data = data_train, 
      method = "rf", 
      trControl = control_rf, 
      tuneGrid = tuneGrid_rf, 
      ntree = ntree, 
      importance = TRUE,
      metric = "Rsquared"  # Optimize for R²; can be optimized for other metrics if needed
    )
    models_rf[[paste("ntree", ntree, sep = "_")]] <- model_rf
  }
  
  # Select the best Random Forest model based on R²
  best_model_name_rf <- names(models_rf)[which.max(sapply(models_rf, function(x) max(x$results$Rsquared)))]
  best_model_rf <- models_rf[[best_model_name_rf]]
  
  # Train the final Random Forest model with the best hyperparameters
  final_rf_model <- randomForest(formula_rf, data = data_train, mtry = best_model_rf$bestTune$mtry, ntree = as.numeric(gsub("ntree_", "", best_model_name_rf)), importance = TRUE)
  
  # Predict on the test set
  final_predictions_rf <- predict(final_rf_model, newdata = data_test)
  
  # Evaluate the Random Forest model on the test set
  final_results_rf <- postResample(pred = final_predictions_rf, obs = data_test$turb_mean)
  
  # Calculate normalized RMSE for Random Forest
  range_rf <- max(data_test$turb_mean) - min(data_test$turb_mean)
  normalized_rmse_rf <- final_results_rf["RMSE"] / range_rf
  
  # Variable importance for Random Forest
  var_importance_rf <- importance(final_rf_model)
  var_imp_rf_df <- data.frame(Variables = rownames(var_importance_rf), Importance = var_importance_rf[,"IncNodePurity"])
  
  # Return the results as a list
  return(list(
    model = final_rf_model, 
    results = final_results_rf, 
    normalized_rmse = normalized_rmse_rf, 
    var_importance = var_imp_rf_df, 
    bestTune = best_model_rf$bestTune, 
    ntree = final_rf_model$ntree
  ))
}

# Running the function multiple times and collecting results
n_iterations <- 30
results_list <- replicate(n_iterations, run_replication(data), simplify = FALSE)

# Extract and save all selected hyperparameters
hyperparams_list <- lapply(results_list, function(x) c(x$bestTune, ntree = x$ntree))
hyperparams_df <- do.call(rbind, hyperparams_list)

# Count the unique combinations of hyperparameters
unique_hyperparams_counts <- hyperparams_df %>%
  group_by(mtry, ntree) %>%
  tally(sort = TRUE)

# Print hyperparameter counts
print(unique_hyperparams_counts)

# Extract and average the metrics
rsquared_values <- sapply(results_list, function(x) x$results["Rsquared"])
rmse_values <- sapply(results_list, function(x) x$results["RMSE"])
normalized_rmse_values <- sapply(results_list, function(x) x$normalized_rmse)

avg_rsquared_rf <- mean(rsquared_values)
avg_rmse_rf <- mean(rmse_values)
avg_normalized_rmse_rf <- mean(normalized_rmse_values)

mean_rsquared_rf <- mean(rsquared_values)
mean_rmse_rf <- mean(rmse_values)
mean_normalized_rmse_rf <- mean(normalized_rmse_values)

# Aggregate variable importances
all_importances <- do.call(rbind, lapply(results_list, function(x) x$var_importance))
avg_importances <- all_importances %>%
  group_by(Variables) %>%
  summarize(Importance = mean(Importance)) %>%
  arrange(desc(Importance))



## Apply the same approach to XGBoost

# Define the number of iterations
n_iterations <- 10

# Create empty lists to store results
rsquared_list <- c()
rmse_list <- c()
normalized_rmse_list <- c()
variable_importance_list <- list()
hyperparameter_list <- list()

# Define the renaming function for variables
rename_variables <- function(df, rename_map) {
  df <- df %>%
    mutate(Variables = case_when(
      Variables %in% names(rename_map) ~ rename_map[Variables],
      TRUE ~ Variables
    ))
  return(df)
}

# Run the model multiple times
set.seed(123)
for (i in 1:n_iterations) {
  # Split the data into training and testing sets
  trainIndex <- createDataPartition(data$turb_mean, p = .75, list = FALSE, times = 1) # train/test split can be changed here
  data_train <- data[trainIndex, ]
  data_test <- data[-trainIndex, ]
  
  # Perform Recursive Feature Elimination (RFE) for XGBoost
  rfe_control_xgb <- rfeControl(functions = rfFuncs, method = "cv", number = 5, verbose = FALSE, returnResamp = "final", saveDetails = TRUE)
  xgb_rfe <- rfe(data_train[, -which(names(data_train) == "turb_mean")],
                 data_train$turb_mean,
                 sizes = c(1:5, 7, 9, 11, 13, 15, 17),
                 rfeControl = rfe_control_xgb)
  
  # Define the formula for XGBoost model using selected features
  selected_vars_xgb <- predictors(xgb_rfe)
  formula_xgb <- as.formula(paste("turb_mean ~", paste(selected_vars_xgb, collapse = "+")))
  
  # Define the grid of hyperparameters for XGBoost
  tune_grid_xgb <- expand.grid(
    nrounds = c(100, 500, 1000),
    max_depth = c(2, 4, 6),
    eta = c(0.01, 0.3, 0.5),
    gamma = 0,
    colsample_bytree = 0.8,
    min_child_weight = 1,
    subsample = 0.8
  )
  
  # Train the XGBoost model using grid search
  train_control_xgb <- trainControl(method = "cv", number = 5, verboseIter = TRUE)
  xgb_model <- train(
    formula_xgb,
    data = data_train,
    method = "xgbTree",
    trControl = train_control_xgb,
    tuneGrid = tune_grid_xgb,
    metric = "Rsquared",
    verbose = TRUE
  )
  
  # Make predictions and calculate metrics
  predictions_xgb <- predict(xgb_model, newdata = data_test)
  
  # Calculate R², RMSE, and normalized RMSE
  rsquared_xgb <- cor(predictions_xgb, data_test$turb_mean)^2
  rsquared_list <- c(rsquared_list, rsquared_xgb)
  
  rmse_xgb <- sqrt(mean((predictions_xgb - data_test$turb_mean)^2))
  rmse_list <- c(rmse_list, rmse_xgb)
  
  range_xgb <- max(data_test$turb_mean) - min(data_test$turb_mean)
  normalized_rmse_xgb <- rmse_xgb / range_xgb
  normalized_rmse_list <- c(normalized_rmse_list, normalized_rmse_xgb)
  
  # Extract and rename variable importance
  var_importance_xgb <- varImp(xgb_model)$importance
  var_imp_df <- as.data.frame(var_importance_xgb)
  var_imp_df$Variables <- rownames(var_imp_df)
  var_imp_df <- rename_variables(var_imp_df, rename_map)
  variable_importance_list[[i]] <- var_imp_df
  
  # Store the best hyperparameters
  hyperparameter_list[[i]] <- xgb_model$bestTune
}

# Combine variable importances and calculate the mean importance
combined_importance <- bind_rows(variable_importance_list) %>%
  group_by(Variables) %>%
  summarize(Importance = mean(Overall, na.rm = TRUE)) %>%
  ungroup()

# Combine hyperparameters and calculate the frequency of each combination
hyperparameters_df <- bind_rows(hyperparameter_list)
hyperparameter_summary <- hyperparameters_df %>%
  group_by_all() %>%
  summarize(Count = n()) %>%
  arrange(desc(Count))

# Calculate average performance metrics
avg_rsquared <- mean(rsquared_list)
avg_rmse <- mean(rmse_list)
avg_normalized_rmse <- mean(normalized_rmse_list)



