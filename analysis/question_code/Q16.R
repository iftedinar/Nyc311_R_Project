for (v in c("problem","borough","open_data_channel_type",
            "weekday")) {
 cat(v,":",nlevels(train[[v]]),"model levels\n")
}
print(maps$open_data_channel_type)
