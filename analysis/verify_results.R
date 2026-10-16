# Independent verification using saved predictions rather than fitted objects.
raw_check <- read.csv("NYC311_April2025_RawSample.csv",colClasses="character",na.strings=c("","NA"))
p <- read.csv("analysis/tables/validation_predictions.csv")
m <- read.csv("analysis/tables/classification_metrics.csv")
l <- read.csv("analysis/tables/linear_metrics.csv")
s <- read.csv("analysis/tables/split_membership.csv")
stopifnot(nrow(raw_check)==40000,ncol(raw_check)==16,
          sum(is.na(raw_check$closed_date))==332,
          !anyDuplicated(s$unique_key),nrow(s)==39668,nrow(p)==11901)
stopifnot(abs(sqrt(mean((p$actual_log-p$predicted_log)^2))-l$RMSE[2])<1e-10)
for (i in seq_len(nrow(m))) {
  flag <- p$slow_probability>=m$cutoff[i]
  stopifnot(sum(flag & p$actual_slow==1)==m$TP[i],
            sum(flag & p$actual_slow==0)==m$FP[i],
            sum(!flag & p$actual_slow==1)==m$FN[i],
            sum(!flag & p$actual_slow==0)==m$TN[i])
}
created_check <- as.POSIXct(raw_check$created_date,format="%Y-%m-%dT%H:%M:%OS",tz="America/New_York")
closed_check <- as.POSIXct(raw_check$closed_date,format="%Y-%m-%dT%H:%M:%OS",tz="America/New_York")
hours_check <- as.numeric(difftime(closed_check,created_check,units="hours"))
ix <- match(p$unique_key,raw_check$unique_key)
stopifnot(all(abs(p$actual_hours-hours_check[ix])<1e-8))
cat("Independent source-row, duration, split, RMSE and confusion-matrix checks passed.\n")
