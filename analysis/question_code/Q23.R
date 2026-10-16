print(head(read.csv("analysis/tables/slow_thresholds.csv")))
cat("Global training q75 hours:",global_q75,"\n")
cat("Training slow rate:",mean(train$slow),"\n")
cat("Validation slow rate:",mean(validation$slow),"\n")
