train$log_resolution_hours <- log1p(train$resolution_hours)
print(summary(train$log_resolution_hours))
