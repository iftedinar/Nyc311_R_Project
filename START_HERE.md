# NYC 311 project

The original CSV, PDF overview, and blank worksheet are unchanged. All calculations, models, charts, and validation measures were run in R 4.6.1 using base R.

## Deliverables

- `NYC311_Completed_Worksheet.docx`: all 9 parts and 31 numbered questions, including response tables, R examples, actual outputs, interpretation, and optional LinkedIn analysis.
- `NYC311_Analysis.R`: complete analysis, with no additional R packages required.
- `NYC311_Business_Presentation.pptx`: business presentation required by the overview.
- `LinkedIn_Project_Article.md`: editable article draft. Nothing has been published.

## Run in RStudio Desktop

1. Open `Nyc311_R_Project.Rproj` in this folder.
2. Open `NYC311_Analysis.R` and click **Source**, or run:

```r
source("NYC311_Analysis.R", echo = TRUE)
```

The script reads the original CSV and recreates `analysis/tables`, `analysis/figures`, model datasets, saved models, and verification records. It overwrites those generated outputs, not the original files. If using R GUI instead, set the working directory to this project folder before sourcing.

To reproduce the worksheet's question-specific console excerpts:

```r
source("analysis/run_question_code.R")
```

This runs the full analysis and then all 31 R examples. Run individual `analysis/question_code/Qxx.R` examples only after the full analysis has populated the R session. Worksheet code is companion code, not 31 independent scripts.

To independently recompute saved validation metrics:

```r
source("analysis/verify_results.R")
```

## Interpretation to retain

There are 40,000 data rows, not 40,001. Of these, 39,668 have usable closure durations. All records are labeled Closed; this is not a representative sample of every incoming or still-open request.

The linear model's 1.3089 RMSE is in log(1 + hours), **not hours**. Converted hour forecasts have poor RMSE. The logistic classifier has weak ranking performance (AUC 0.5542) and highly uneven borough flag rates. The recommendation is further evaluation and a monitored pilot, not automatic deployment.

The 70/30 split uses seed 353. Rare-category mappings and slow thresholds use training data only. The 0.25 classification cutoff is a stated screening assumption, not a cutoff optimized against known costs. Validation comparisons of alternative cutoffs are exploratory.

At cutoff 0.50, precision appears as `NaN` in R because there are no predicted positives: the precision calculation is 0/0 and is undefined. This is an expected property of that comparison, not a failed R run.

## Before class submission

The name is the permitted placeholder **NYC 311 Analytics Student**. Replace it if desired. Review the AI disclosure and learning reflection so they accurately describe your own work and understanding. The assignment explicitly includes a tool-use reflection; the completed worksheet discloses AI assistance and actual R execution.

The DOCX and slides are snapshots of the saved analysis. If you change the model or source data, update the narrative and rebuild the documents too. The Python and JavaScript files in `analysis/` assemble documents; they do not perform the statistical analysis.

## Supporting files

`analysis/tables/` contains full frequency tables, cross-tabulations, cleaning decisions, model coefficients, and metrics. `analysis/figures/` contains R charts. `analysis/question_output/` contains actual R output for every question. `analysis/sessionInfo.txt` records the R environment. `analysis/qa/` holds private rendering and checking files and is not a class submission requirement.
