print(read.csv("analysis/tables/weekday_adjusted.csv"))
print(range(table(d$day)))
print(sort(table(d$hour), decreasing=TRUE)[c(1,24)])
