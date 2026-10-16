print(table(reason))
cat("Duplicate keys:",sum(duplicated(raw$unique_key)),"\n")
cat("Negative durations:",
    sum(d$resolution_hours<0,na.rm=TRUE),"\n")
