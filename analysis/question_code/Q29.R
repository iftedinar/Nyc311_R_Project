print(table(raw$status))
print(range(d$created))
cat("Excluded unlabeled durations:",sum(reason!="Retained"),"\n")
