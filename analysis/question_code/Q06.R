print(category_summary, row.names = FALSE)
for (v in cats) {
  cat("\n", v, "\n")
  print(head(sort(table(raw[[v]], useNA="ifany"),
                  decreasing=TRUE), 3))
}
