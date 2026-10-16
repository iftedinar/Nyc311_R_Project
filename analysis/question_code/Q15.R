cat("Missing final training predictors:",
    sum(is.na(train[,predictors])),"\n")
cat("Missing final validation predictors:",
    sum(is.na(validation[,predictors])),"\n")
