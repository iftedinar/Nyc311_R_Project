ap <- table(raw$problem,raw$agency)
cat("Single-agency problem types:",
    sum(rowSums(ap>0)==1), "of", nrow(ap), "\n")
print(table(raw$agency,raw$problem)[
  c("NYPD","HPD","EDC"),
  c("Illegal Parking","HEAT/HOT WATER","Noise - Helicopter")])
print(round(100*prop.table(
  table(raw$borough,raw$open_data_channel_type),1),2))
