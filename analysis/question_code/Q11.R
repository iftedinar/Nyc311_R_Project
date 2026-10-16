cat("Median hours:",median(clean$resolution_hours),"\n")
cat("Mean hours:",mean(clean$resolution_hours),"\n")
cat("Closed status without closed_date:",
    sum(raw$status=="Closed" & is.na(raw$closed_date)),"\n")
