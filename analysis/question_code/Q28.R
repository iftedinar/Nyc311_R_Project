print(read.csv("analysis/tables/optional_borough_monitor.csv")[,
 c("borough","n","sensitivity","specificity","flag_rate")],
 row.names=FALSE)
