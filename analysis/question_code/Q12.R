resolution_hours <- as.numeric(difftime(
  d$closed,d$created,units="hours"))
print(head(resolution_hours))
