"""Document assembly content only. Every numeric analysis is computed in R."""
from pathlib import Path
import json

answers = {
7: 'City operations leaders need to identify incoming requests that may take longer to close so they can plan follow-up and allocate limited attention. This project estimates recorded closure time and screens for unusually slow requests within comparable problem types. Recorded closure is an administrative outcome and does not establish that the underlying issue was fixed. The supplied sample contains only records marked Closed, which limits its representativeness for new incoming requests.',
25: 'Predict log(1 + resolution_hours), where resolution_hours is the elapsed time from creation to recorded closure. Report validation RMSE on this transformed scale and separately check predictions converted to hours.',
27: 'Predict the probability that a request exceeds the training-set 75th percentile of closure time for its original problem type. The outcome is 1 for slow and 0 otherwise; small or unseen types use a global training threshold.',
31: 'Use estimates to plan monitoring and follow-up queues, alongside urgency, service commitments, and staff judgment. The weak slow-request model should be evaluated in a monitored pilot before operational use. Its predictions should not determine which residents receive service.',
39: 'The CSV has 40,000 data records and 16 columns; 40,001 counts the header as a row. Removing 332 records without closed timestamps leaves 39,668. No duplicate keys, invalid created timestamps, negative durations, or out-of-April created dates were removed. The exported model datasets have eight columns: six predictors and two outcomes. Categorical predictors expand into multiple regression coefficients.',
45: 'due_date is missing for 39,766 records (99.415%); additional_details for 22,528 (56.320%); location_type for 4,532 (11.330%). All 16 columns appear in the table.',
47: 'due_date is almost entirely absent and its availability at initial submission is not established, so it is excluded. additional_details is an incomplete free-text field and is omitted from this introductory model. Missing location_type could be encoded, but the field is ultimately excluded because some levels exactly duplicate problem types in the training design matrix.',
49: 'A blank detail or location field may reflect an issue for which that field is not applicable, or inconsistent collection. The file cannot distinguish these explanations. Missing closed_date does not mean zero hours: 332 such records are labeled Closed, but their duration cannot be computed.',
54: 'Problem type should capture differences in agency workflow and task complexity. Borough, submission channel, and creation time may add context. Agency is descriptively informative but is largely determined by problem type, making separate causal interpretations inappropriate.',
56: 'There are 142 problem types and 598 problem-detail categories including Missing; 84 and 529 respectively have fewer than 100 observations. Location type has 83 categories and community board 75. Sparse categories increase instability and make unseen validation levels difficult.',
58: 'Problem categories with fewer than 100 training records are pooled as Other. Borough is retained. The single rare channel is mapped to the training modal channel ONLINE because its combined rare group is too small to estimate. Future unseen levels use the saved training mapping. Agency, problem_detail, location_type, community_board, and ZIP are omitted for redundancy, sparsity, or parsimony. All mappings are learned on training rows only.',
66: 'Counts are uneven: April 25 has 1,541 records, April 30 only 361, and April 1 has 959. This is a supplied sample, not a verified complete month of city demand. The boundary-day differences may reflect sample coverage and should not be interpreted as actual citywide demand changes.',
68: 'Tuesday has the most total records (6,770), but April contains five Tuesdays. After dividing by calendar-day counts, Thursday averages 1,429.75 requests per day and Wednesday 1,244.80. The peak hour is 09:00 with 2,325 requests; 04:00 has 453. These are descriptive sample patterns.',
70: 'Created weekday is a seven-level factor. Hour is encoded by sine and cosine so 23:00 and 00:00 remain adjacent. Day of month and weekend are also created for EDA. They are not final predictors: weekday already expresses weekend membership, and a single-month day trend may not generalize.',
79: 'The raw distribution is strongly right-skewed: median 6.68 hours versus mean 251.36 hours. A small fraction of very long cases stretches the horizontal axis. The 95th percentile is 1,251.44 hours and the maximum 9,888.18 hours.',
81: 'log1p(resolution_hours) compresses the upper tail and retains valid zero-hour records. Linear regression then minimizes squared error in log(1 + hours), emphasizing relative differences. Better log-scale fit does not guarantee accurate hour-scale forecasts.',
83: 'There are 677 zero-hour records and 2,930 records over 30 days. Both are retained because equal timestamps and long durations are possible and cannot be proven erroneous from this file. Their interpretation requires caution. The log transformation reduces their leverage; negative durations would be excluded, but none occur.',
95: 'Among agencies with at least 100 eligible records, EDC has median 7,254.84 hours (n = 251), TLC 1,213.84 (n = 409), and DOB 293.82 (n = 1,202). Noise - Helicopter has median 7,254.84 hours and Building/Use 2,488.14 hours. These are recorded closure patterns, not an agency performance ranking adjusted for case mix.',
97: 'NYPD has median 1.43 hours across 18,997 requests. Rodent has median zero hours across 450 records; that is a timestamp observation, not evidence of instantaneous pest removal. Small categories are not used to establish reliable rankings.',
99: 'Different problem types require different actions and have different recorded workflows. A universal threshold would label naturally lengthy work slow even when it is typical for that problem. A within-problem percentile creates a relative comparison, although it is not an official service-level deadline.',
104: 'Yes. In the supplied sample, 138 of 142 problem types occur entirely within one agency. The full agency-by-problem table is saved, and a compact excerpt is included below. Agency and problem should therefore not be interpreted as independent drivers.',
106: 'Submission channel mix differs by borough. Phone accounts for 34.66% of Bronx records versus 24.37% of Manhattan records; online accounts for 36.69% versus 46.98%. These proportions describe recorded users and request mix, not all residents or access needs. The problem-by-borough table is also saved for inspection.',
108: 'Correlated predictors can make individual coefficients unstable or redundant. Channel and borough associations may reflect differences in problem mix and reporting behavior. I retain problem but omit agency; I also remove location_type after its training-only design check finds exact redundancy. Model coefficients are associations, not causal effects.',
113: 'Problem is expected to be most informative for absolute closure duration; borough, channel, weekday, and cyclic hour may add information. For relative slow status, the problem-based definition removes much of the between-problem signal, so good duration prediction need not imply good slow-request classification.',
115: 'The 332 Closed records without closed_date cannot provide a target. They are removed without inventing outcomes. More broadly, all statuses are Closed, so the sample may exclude still-open requests and underestimate delays among all incoming requests.',
120: 'Parse created_date and closed_date as NYC local timestamps, then calculate as.numeric(difftime(closed, created, units = "hours")). April has no daylight-saving transition. This measures time to recorded closure; it is not a direct measure of resident satisfaction or confirmed problem resolution.',
150: 'A reproducible 70/30 random holdout provides 27,767 training rows and 11,901 validation rows, using seed 353. It leaves enough examples for estimating categorical effects and a substantial unseen evaluation set. The split is performed before rare-level mappings and slow thresholds are estimated.',
152: 'Training performance is optimistic because the same observations estimated the coefficients. Validation measures performance on held-out records. This random within-April split still does not test future months or dependence between related requests; a later-month test is needed before deployment.',
156: 'log_resolution_hours = log1p(resolution_hours).',
159: 'Yes. I used the natural logarithm of 1 plus hours, which is defined at zero and reduces the influence of the long upper tail.',
161: 'Closure duration is nonnegative and extremely skewed. The transformation supports modeling broad relative duration patterns while keeping zero-hour records. I also evaluate a training-residual smearing conversion to hours to avoid presenting transformed performance as an hour-scale error.',
168: 'Validation RMSE is 1.3089 log1p-hours versus 2.2388 for predicting the training mean log duration. Validation MAE is 0.9278 and predictive R-squared is 0.6582. RMSE is not 1.31 hours. On the hour scale, smearing-adjusted RMSE is 1,373.18 hours, worse than the training-mean baseline of 970.97 hours.',
170: 'Training RMSE is 1.2938 and validation RMSE is 1.3089, a small increase of 0.0151. This does not suggest a large overfitting gap on this split, but it does not establish future-month reliability or eliminate sampling bias.',
173: 'The model explains substantial variation on the transformed scale using problem type and submission context. Validation predictive R-squared is 0.6582, and log-scale RMSE improves over the intercept-only baseline. Coefficients and residual plots are saved for review; the residual spread and hour-scale errors show substantial remaining uncertainty.',
175: 'It may support broad planning about relative closure duration, but it is not reliable for individual completion-time promises. The smearing-adjusted hour-scale RMSE is worse than a simple mean baseline, even though hour-scale MAE improves from 392.31 to 316.65 hours. Large cases dominate squared error.',
182: 'A request is slow if its duration is strictly greater than the training-set 75th percentile for its original problem type (R quantile type 7). If a problem has fewer than 30 training records or was unseen in training, use the global training 75th percentile. Validation labels use these frozen training thresholds; ties are not slow.',
184: 'This compares requests with broadly similar work and uses only training data to set benchmarks. The threshold is a relative historical benchmark, not an official SLA. Ties and the global fallback mean the slow fraction is not exactly 25%: training is 25.21% and validation 26.17%. Small categories have a less comparable fallback.',
190: 'The 0.25 cutoff was set before fitting as a screening-oriented choice for an outcome near 25% prevalence. It is not an optimized business cutoff because error costs and queue capacity are unknown. The 0.50 comparison flags no records, so its 73.83% accuracy hides zero recall. At 0.25, 44.99% of validation requests are flagged.',
197: 'Sensitivity is important because missed slow requests lose an opportunity for early follow-up. It is 50.24%, so about half are still missed. Precision (29.23%) and flag volume are also essential: 3,789 false alerts create workload. Accuracy alone is misleading; AUC is only 0.5542, indicating weak ranking ability.',
200: 'At cutoff 0.25, 99.43% of Bronx validation requests are flagged, compared with 20.94% in Brooklyn and 1.17% in Staten Island. Phone submissions are flagged 50.70% versus 39.03% online. These are model flag rates, not causal effects or proof of fair treatment. The borough imbalance is a major reason to avoid automatic triage.',
204: 'A false negative is more concerning for the screening objective because an actually slow request receives no early flag. There are 1,550 false negatives. However, the 3,789 false positives would divert staff time, so false-positive costs and capacity must also shape any future cutoff.',
211: 'Do not deploy the current classifier for automatic prioritization. Use the descriptive results to investigate long recorded closure workflows and missing timestamps. If predictions are piloted, run them in shadow mode with staff review, compare against simple operational rules, and test a later-month sample including open requests. Set a review-capacity limit and explicit costs before selecting a cutoff.',
214: 'A slow prediction does not measure urgency, harm, or service eligibility. Keep safety and established service obligations ahead of the model. Monitor recall, false-positive rates, and workload by borough and problem type. Closure timestamps may reflect administrative practices. Do not infer that borough causes delays or that closed means the problem was fixed.',
223: 'Yes. Codex AI helped inspect the assignment, draft base-R code, interpret outputs, and assemble the worksheet and presentation. The analysis was executed in R 4.6.1. Automated checks verified nonoverlapping splits, valid targets, complete predictions, full model rank, logistic convergence, and confusion-matrix totals. All numeric results come from saved R outputs; document assembly used Python. The student should rerun the script and review the interpretations before submission.',
226: 'A key modeling lesson is that a transformation changes what prediction error means. log1p kept zero-hour observations and improved prediction on the transformed scale, but converting predictions back to hours did not beat the mean baseline on RMSE. This shows why I need to connect evaluation units to the business decision, rather than treating a good transformed R-squared as a promise of accurate completion times.'
}

# Each question gets executable R code and actual output in the worksheet.
snippets = {
1:'cat("Goal: anticipate recorded closure delays at initial submission.\\n")',
2:'print(business_goal)',
3:'cat("Use: reviewed follow-up planning; validate before operational triage.\\n")',
4:'print(split_summary)',
5:'print(missingness, row.names = FALSE)',
6:'print(category_summary, row.names = FALSE)\nfor (v in cats) {\n  cat("\\n", v, "\\n")\n  print(head(sort(table(raw[[v]], useNA="ifany"),\n                  decreasing=TRUE), 3))\n}',
7:'print(read.csv("analysis/tables/weekday_adjusted.csv"))\nprint(range(table(d$day)))\nprint(sort(table(d$hour), decreasing=TRUE)[c(1,24)])',
8:'print(duration_summary, row.names=FALSE)\nhist(clean$resolution_hours, breaks=60)\nhist(clean$log_resolution_hours, breaks=50)',
9:'for (v in c("agency", "problem", "borough",\n            "open_data_channel_type")) {\n  z <- read.csv(paste0("analysis/tables/duration_by_",v,".csv"))\n  cat("\\n",v," (n >= 100)\\n")\n  print(head(z[z$n >= 100,], 4), row.names=FALSE)\n}',
10:'ap <- table(raw$problem,raw$agency)\ncat("Single-agency problem types:",\n    sum(rowSums(ap>0)==1), "of", nrow(ap), "\\n")\nprint(table(raw$agency,raw$problem)[\n  c("NYPD","HPD","EDC"),\n  c("Illegal Parking","HEAT/HOT WATER","Noise - Helicopter")])\nprint(round(100*prop.table(\n  table(raw$borough,raw$open_data_channel_type),1),2))',
11:'cat("Median hours:",median(clean$resolution_hours),"\\n")\ncat("Mean hours:",mean(clean$resolution_hours),"\\n")\ncat("Closed status without closed_date:",\n    sum(raw$status=="Closed" & is.na(raw$closed_date)),"\\n")',
12:'resolution_hours <- as.numeric(difftime(\n  d$closed,d$created,units="hours"))\nprint(head(resolution_hours))',
13:'print(table(reason))\ncat("Duplicate keys:",sum(duplicated(raw$unique_key)),"\\n")\ncat("Negative durations:",\n    sum(d$resolution_hours<0,na.rm=TRUE),"\\n")',
14:'print(head(clean[,c("day","hour","weekday","weekend",\n  "hour_sin","hour_cos","resolution_hours",\n  "log_resolution_hours")]),row.names=FALSE)',
15:'cat("Missing final training predictors:",\n    sum(is.na(train[,predictors])),"\\n")\ncat("Missing final validation predictors:",\n    sum(is.na(validation[,predictors])),"\\n")',
16:'for (v in c("problem","borough","open_data_channel_type",\n            "weekday")) {\n cat(v,":",nlevels(train[[v]]),"model levels\\n")\n}\nprint(maps$open_data_channel_type)',
17:'leakage <- c("closed_date","status","resolution_description",\n "resolution_action_updated_date","resolution_hours",\n "log_resolution_hours","slow")\nstopifnot(!any(predictors %in% leakage))\ncat("Leakage predictor check passed.\\n")',
18:'print(predictors)\nprint(formula(linear))\nprint(formula(logistic))',
19:'print(table(ifelse(seq_len(nrow(clean)) %in% train_id,\n                   "Training","Validation")))\ncat("Seed: 353; training fraction:",\n    nrow(train)/nrow(clean),"\\n")\nstopifnot(!any(train$unique_key %in% validation$unique_key))',
20:'train$log_resolution_hours <- log1p(train$resolution_hours)\nprint(summary(train$log_resolution_hours))',
21:'linear <- lm(reformulate(predictors,\n                         "log_resolution_hours"), data=train)\npred_valid <- predict(linear, newdata=validation)\nsqrt(mean((validation$log_resolution_hours-pred_valid)^2))\nprint(linear_metrics,row.names=FALSE)\nprint(hours_metrics,row.names=FALSE)',
22:'print(read.csv("analysis/tables/linear_baseline_log.csv"))\ncat("Training residual smearing factor:",smearing,"\\n")',
23:'print(head(read.csv("analysis/tables/slow_thresholds.csv")))\ncat("Global training q75 hours:",global_q75,"\\n")\ncat("Training slow rate:",mean(train$slow),"\\n")\ncat("Validation slow rate:",mean(validation$slow),"\\n")',
24:'logistic <- glm(reformulate(predictors,"slow"),\n                data=train, family=binomial())\nprob <- predict(logistic, newdata=validation,\n                type="response")\nprint(classification_metrics,row.names=FALSE)\ncat("Validation AUC:",auc,"\\n")',
25:'print(read.csv("analysis/tables/validation_risk_borough.csv"),\n      row.names=FALSE)\nprint(read.csv(\n "analysis/tables/validation_risk_open_data_channel_type.csv"),\n row.names=FALSE)',
26:'cat("Median/mean hours:",median(y),mean(y),"\\n")\nprint(linear_metrics[2,],row.names=FALSE)\nprint(classification_metrics[1,],row.names=FALSE)',
27:'cat("Flags per 1000:",round(1000*mean(prob>=.25)),"\\n")\ncat("Correct flags per 1000:",\n    round(1000*sum(prob>=.25 & validation$slow==1)/\n          nrow(validation)),"\\n")',
28:'print(read.csv("analysis/tables/optional_borough_monitor.csv")[,\n c("borough","n","sensitivity","specificity","flag_rate")],\n row.names=FALSE)',
29:'print(table(raw$status))\nprint(range(d$created))\ncat("Excluded unlabeled durations:",sum(reason!="Retained"),"\\n")',
30:'cat(R.version.string,"\\n")\ncat(readLines("analysis/verification.txt"),sep="\\n")',
31:'print(hours_metrics,row.names=FALSE)\ncat("Compare errors on the scale needed for the decision.\\n")'
}
Path('analysis/question_code').mkdir(exist_ok=True)
for q,code in snippets.items():
 Path(f'analysis/question_code/Q{q:02}.R').write_text(code+'\n',encoding='utf-8')
Path('analysis/worksheet_content.json').write_text(json.dumps({'answers':answers,'snippets':snippets},indent=2),encoding='utf-8')
Path('analysis/run_question_code.R').write_text('''# Run the full analysis first, then capture each worksheet example.
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
''',encoding='utf-8')
