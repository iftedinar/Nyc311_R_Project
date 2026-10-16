leakage <- c("closed_date","status","resolution_description",
 "resolution_action_updated_date","resolution_hours",
 "log_resolution_hours","slow")
stopifnot(!any(predictors %in% leakage))
cat("Leakage predictor check passed.\n")
