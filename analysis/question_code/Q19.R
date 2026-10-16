print(table(ifelse(seq_len(nrow(clean)) %in% train_id,
                   "Training","Validation")))
cat("Seed: 353; training fraction:",
    nrow(train)/nrow(clean),"\n")
stopifnot(!any(train$unique_key %in% validation$unique_key))
