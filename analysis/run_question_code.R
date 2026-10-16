# Run the full analysis first, then capture each worksheet example.
source("NYC311_Analysis.R")
options(width=78, digits=6)
dir.create("analysis/question_output",showWarnings=FALSE)
pdf("analysis/qa/question_plots.pdf")
for (q in 1:31) {
  code_file <- sprintf("analysis/question_code/Q%02d.R",q)
  output_file <- sprintf("analysis/question_output/Q%02d.txt",q)
  sink(output_file)
  source(code_file,echo=FALSE)
  sink()
}
dev.off()
