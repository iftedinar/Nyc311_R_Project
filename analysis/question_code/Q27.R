cat("Flags per 1000:",round(1000*mean(prob>=.25)),"\n")
cat("Correct flags per 1000:",
    round(1000*sum(prob>=.25 & validation$slow==1)/
          nrow(validation)),"\n")
