for (v in c("agency", "problem", "borough",
            "open_data_channel_type")) {
  z <- read.csv(paste0("analysis/tables/duration_by_",v,".csv"))
  cat("\n",v," (n >= 100)\n")
  print(head(z[z$n >= 100,], 4), row.names=FALSE)
}
