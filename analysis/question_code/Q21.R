linear <- lm(reformulate(predictors,
                         "log_resolution_hours"), data=train)
pred_valid <- predict(linear, newdata=validation)
sqrt(mean((validation$log_resolution_hours-pred_valid)^2))
print(linear_metrics,row.names=FALSE)
print(hours_metrics,row.names=FALSE)
