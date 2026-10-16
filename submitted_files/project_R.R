library(readr)

# NYC 311 April 2025 | Complete reproducible course analysis
# Run from this project folder: source("NYC311_Analysis.R", echo = TRUE)
# Base R only. No package installation is needed. See worksheet for interpretation.
options(width = 100, stringsAsFactors = FALSE)
Sys.setenv(TZ = "America/New_York")
dir.create("analysis/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("analysis/figures", recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, paste0("analysis/tables/", name, ".csv"), row.names = FALSE)
png_start <- function(name, w=1400, h=900) {
  png(paste0("analysis/figures/",name,".png"), width=w,height=h,res=150)
  par(mar=c(5,5,4,2), col.axis="#243746", col.lab="#243746")
}

# Q01-Q03 Business understanding: two outcomes, prediction at initial submission.
business_goal <- data.frame(model=c("Linear regression","Logistic regression"),
                            target=c("log(1 + hours to recorded closure)","Above training problem-specific 75th percentile"))
save_table(business_goal,"business_goal")

# Q04 Initial data review. Import as text to preserve ZIP codes and identifiers.
raw <- read.csv("NYC311_April2025_RawSample.csv", colClasses="character",
                na.strings=c("", "NA"), check.names=FALSE)
raw[] <- lapply(raw, function(x) { x <- trimws(x); x[x == ""] <- NA_character_; x })
stopifnot(ncol(raw)==16, !anyNA(raw$unique_key))
print(dim(raw))

# Q05 Missingness in all original fields (before filtering).
missingness <- data.frame(variable=names(raw), missing=colSums(is.na(raw)),
                          percent=100*colMeans(is.na(raw)))
save_table(missingness,"missingness")
print(missingness)

# Q06 All categorical frequencies, including explicit missing categories.
cats <- c("agency","problem","problem_detail","location_type","borough",
          "community_board","open_data_channel_type")
category_summary <- data.frame()
for (v in cats) {
  x <- raw[[v]]; x[is.na(x)] <- "Missing"
  counts <- sort(table(x),decreasing=TRUE)
  out <- data.frame(category=names(counts),n=as.integer(counts),percent=100*as.integer(counts)/nrow(raw))
  save_table(out,paste0("frequency_",v))
  category_summary <- rbind(category_summary,data.frame(variable=v,levels=length(counts),
                                                        rare_under_100=sum(counts<100)))
  png_start(paste0("frequency_",v)); par(mar=c(5,16,4,2))
  top <- head(counts,10)
  barplot(rev(top),horiz=TRUE,las=1,col="#287D8E",cex.names=.75,
          main=paste("Most common",v),xlab="Requests in supplied sample")
  dev.off()
}
save_table(category_summary,"category_summary")

# Q07 Date patterns. NYC local timestamps; April has no daylight-saving transition.
parse_time <- function(x) as.POSIXct(x,format="%Y-%m-%dT%H:%M:%OS",tz="America/New_York")
d <- raw
d$created <- parse_time(d$created_date); d$closed <- parse_time(d$closed_date)
d$day <- as.integer(format(d$created,"%d"))
d$hour <- as.integer(format(d$created,"%H"))
d$weekday <- factor(as.integer(format(d$created,"%u")),levels=1:7,
                    labels=c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"))
d$weekend <- as.integer(d$weekday %in% c("Sat","Sun"))
d$hour_sin <- sin(2*pi*d$hour/24); d$hour_cos <- cos(2*pi*d$hour/24)
for (v in c("day","weekday","hour","weekend")) {
  z <- table(d[[v]])
  save_table(data.frame(category=names(z),n=as.integer(z)),paste0("time_",v))
  png_start(paste0("time_",v)); barplot(z,col="#287D8E",main=paste("Requests by",v),ylab="Requests"); dev.off()
}
calendar <- seq(as.Date("2025-04-01"),as.Date("2025-04-30"),by="day")
weekday_days <- table(factor(as.integer(format(calendar,"%u")),levels=1:7,labels=levels(d$weekday)))
save_table(data.frame(weekday=levels(d$weekday),requests=as.integer(table(d$weekday)),
                      calendar_days=as.integer(weekday_days),per_day=as.integer(table(d$weekday))/as.integer(weekday_days)),"weekday_adjusted")

# Q08 and Q12-Q13 Resolution time and sequential exclusions.
d$resolution_hours <- as.numeric(difftime(d$closed,d$created,units="hours"))
reason <- rep("Retained",nrow(d))
reason[duplicated(d$unique_key)] <- "Duplicate key"
reason[reason=="Retained" & is.na(d$created)] <- "Missing or invalid created date"
reason[reason=="Retained" & is.na(d$closed)] <- "Missing or invalid closed date"
reason[reason=="Retained" & !is.na(d$resolution_hours) & d$resolution_hours<0] <- "Negative duration"
reason[reason=="Retained" & format(d$created,"%Y-%m")!="2025-04"] <- "Outside April 2025"
save_table(data.frame(reason=names(table(reason)),n=as.integer(table(reason))),"cleaning")
save_table(data.frame(unique_key=d$unique_key,decision=reason),"record_audit")
clean <- d[reason=="Retained",]
clean$log_resolution_hours <- log1p(clean$resolution_hours)
y <- clean$resolution_hours
duration_summary <- data.frame(statistic=c("Minimum","Mean","Median","75th percentile","90th percentile",
                                           "95th percentile","Maximum","Zero hours","Over 30 days"),
                               value=c(min(y),mean(y),median(y),quantile(y,c(.75,.9,.95)),max(y),sum(y==0),sum(y>720)))
save_table(duration_summary,"duration_summary"); print(duration_summary)
png_start("resolution_histograms",1600,750); par(mfrow=c(1,2))
hist(y,breaks=60,col="#287D8E",main="Raw closure duration",xlab="Hours")
hist(log1p(y),breaks=50,col="#287D8E",main="Log transformed duration",xlab="log(1 + hours)"); dev.off()

# Q09 Group comparisons; report sample sizes and avoid ranking tiny groups.
for (v in c("agency","problem","borough","open_data_channel_type")) {
  groups <- split(clean$resolution_hours,clean[[v]])
  z <- data.frame(category=names(groups),n=sapply(groups,length),median=sapply(groups,median),mean=sapply(groups,mean))
  z <- z[order(-z$median),]; save_table(z,paste0("duration_by_",v))
}
png_start("borough_duration"); boxplot(log_resolution_hours~borough,data=clean,col="#80B7C1",
                                       main="Closure duration by borough",ylab="log(1 + hours)",xlab="",cex.axis=.75); dev.off()

# Q10 Cross-tabulations. Raw counts plus within-row percentages.
for (pair in list(c("agency","problem"),c("borough","open_data_channel_type"),c("problem","borough"))) {
  z <- table(raw[[pair[1]]],raw[[pair[2]]]); label <- paste(pair,collapse="_by_")
  save_table(data.frame(category=rownames(z),as.data.frame.matrix(z),check.names=FALSE),paste0("crosstab_",label))
  save_table(data.frame(category=rownames(z),100*as.data.frame.matrix(prop.table(z,1)),check.names=FALSE),paste0("row_percent_",label))
}
ap <- table(raw$problem,raw$agency)
save_table(data.frame(problem=rownames(ap),n=rowSums(ap),agency=colnames(ap)[max.col(ap,ties.method="first")],
                      dominant_share=apply(ap,1,max)/rowSums(ap)),"problem_agency_concentration")

# Q11, Q14-Q19 Preparation and holdout validation.
# Split BEFORE estimating rare-category mappings or slow thresholds.
set.seed(353)
train_id <- sample(seq_len(nrow(clean)),size=floor(.70*nrow(clean)))
train <- clean[train_id,]; validation <- clean[-train_id,]
# Agency is excluded because problem largely identifies agency. Avoid collinearity.
# Detail/ZIP/community board omitted to keep an interpretable introductory model.
predictors <- c("problem","borough","open_data_channel_type",
                "weekday","hour_sin","hour_cos")
maps <- list()
for (v in c("problem","location_type","borough","open_data_channel_type")) {
  a <- train[[v]]; a[is.na(a)] <- "Missing"
  b <- validation[[v]]; b[is.na(b)] <- "Missing"
  freq <- table(a); keep <- names(freq)[freq>=100]
  aa <- ifelse(a %in% keep,a,"Other")
  if (sum(aa=="Other")<100) aa[aa=="Other"] <- names(sort(freq,decreasing=TRUE))[1]
  # If no Other training rows exist, unseen levels use training modal category.
  fallback <- if ("Other" %in% aa) "Other" else names(sort(table(aa),decreasing=TRUE))[1]
  bb <- ifelse(b %in% keep,b,fallback)
  lev <- c(names(sort(table(aa),decreasing=TRUE))[1],sort(setdiff(unique(aa),names(sort(table(aa),decreasing=TRUE))[1])))
  train[[v]] <- factor(aa,levels=lev); validation[[v]] <- factor(bb,levels=lev)
  maps[[v]] <- list(keep=keep,levels=lev,fallback=fallback)
  save_table(data.frame(raw_level=names(freq),n=as.integer(freq),model_level=ifelse(names(freq)%in%keep,names(freq),fallback)),paste0("mapping_",v))
}
split_summary <- data.frame(item=c("Raw rows","Raw columns","Eligible rows","Training rows","Validation rows","Seed","Predictor variables","Model columns including two outcomes"),
                            value=c(nrow(raw),ncol(raw),nrow(clean),nrow(train),nrow(validation),353,length(predictors),length(predictors)+2))
save_table(split_summary,"split_summary")
save_table(data.frame(unique_key=clean$unique_key,split=ifelse(seq_len(nrow(clean))%in%train_id,"training","validation")),"split_membership")

# Q20-Q22 Linear regression. Primary metrics are on log1p-hours scale.
linear <- lm(reformulate(predictors,"log_resolution_hours"),data=train)
stopifnot(!anyNA(coef(linear)))
pred_train <- predict(linear,train); pred_valid <- predict(linear,validation)
reg_metrics <- function(y,p) c(RMSE=sqrt(mean((y-p)^2)),MAE=mean(abs(y-p)),R_squared=1-sum((y-p)^2)/sum((y-mean(y))^2))
linear_metrics <- rbind(data.frame(set="Training",t(reg_metrics(train$log_resolution_hours,pred_train))),
                        data.frame(set="Validation",t(reg_metrics(validation$log_resolution_hours,pred_valid))))
save_table(linear_metrics,"linear_metrics")
baseline_log <- rep(mean(train$log_resolution_hours),nrow(validation))
save_table(data.frame(t(reg_metrics(validation$log_resolution_hours,baseline_log))),"linear_baseline_log")
# Duan smearing uses TRAINING residuals only; evaluate its hours-scale limitations.
smearing <- mean(exp(residuals(linear)))
pred_hours <- pmax(0,exp(pred_valid)*smearing-1)
hours_metrics <- rbind(data.frame(model="Smearing adjusted linear",t(reg_metrics(validation$resolution_hours,pred_hours))),
                       data.frame(model="Training mean baseline",t(reg_metrics(validation$resolution_hours,rep(mean(train$resolution_hours),nrow(validation))))))
save_table(hours_metrics,"hours_metrics")
save_table(data.frame(term=names(coef(linear)),estimate=coef(linear)),"linear_coefficients")
png_start("linear_diagnostics",1500,750); par(mfrow=c(1,2))
plot(pred_valid,validation$log_resolution_hours,pch=16,cex=.25,col=adjustcolor("#287D8E",.15),
     xlab="Predicted log(1 + hours)",ylab="Observed log(1 + hours)",main="Validation predictions"); abline(0,1,col="red")
plot(pred_valid,validation$log_resolution_hours-pred_valid,pch=16,cex=.25,col=adjustcolor("#287D8E",.15),
     xlab="Predicted log(1 + hours)",ylab="Residual",main="Validation residuals"); abline(h=0,col="red"); dev.off()

# Q23 Slow definition. Quantiles learned from TRAINING original problem types.
# Types with fewer than 30 training examples use the global training percentile.
training_problem <- clean$problem[train_id]
validation_problem <- clean$problem[-train_id]
global_q75 <- unname(quantile(train$resolution_hours,.75,type=7))
by_problem <- split(train$resolution_hours,training_problem)
thresholds <- sapply(by_problem,function(x) if(length(x)>=30) unname(quantile(x,.75,type=7)) else global_q75)
get_threshold <- function(p) { q <- unname(thresholds[p]); q[is.na(q)] <- global_q75; q }
train$slow <- as.integer(train$resolution_hours>get_threshold(training_problem))
validation$slow <- as.integer(validation$resolution_hours>get_threshold(validation_problem))
save_table(data.frame(problem=names(thresholds),training_n=sapply(by_problem,length),threshold_hours=thresholds,
                      fallback=sapply(by_problem,length)<30),"slow_thresholds")

# Q24-Q25 Logistic regression. 0.25 fixed in advance for screening-oriented recall.
# Compare 0.50 as a sensitivity analysis, not as validation-driven tuning.
logistic <- glm(reformulate(predictors,"slow"),data=train,family=binomial(),control=glm.control(maxit=100))
stopifnot(logistic$converged,!anyNA(coef(logistic)))
prob <- predict(logistic,validation,type="response")
classification <- function(y,p,cutoff) {
  flag <- p>=cutoff; TP<-sum(flag & y==1); FP<-sum(flag & y==0)
  TN<-sum(!flag & y==0); FN<-sum(!flag & y==1)
  data.frame(cutoff=cutoff,TN=TN,FP=FP,FN=FN,TP=TP,accuracy=(TP+TN)/length(y),
             sensitivity=TP/(TP+FN),specificity=TN/(TN+FP),precision=TP/(TP+FP),
             F1=2*TP/(2*TP+FP+FN),flag_rate=mean(flag))
}
classification_metrics <- rbind(classification(validation$slow,prob,.25),classification(validation$slow,prob,.5))
save_table(classification_metrics,"classification_metrics")
auc <- (sum(rank(prob)[validation$slow==1])-sum(validation$slow==1)*(sum(validation$slow==1)+1)/2)/
  (sum(validation$slow==1)*sum(validation$slow==0))
save_table(data.frame(AUC=auc,Brier=mean((validation$slow-prob)^2),
                      prevalence=mean(validation$slow),majority_accuracy=mean(validation$slow==0),
                      train_prevalence=mean(train$slow),smearing=smearing),"model_extras")
save_table(data.frame(term=names(coef(logistic)),estimate=coef(logistic),odds_ratio=exp(coef(logistic))),"logistic_coefficients")
for (v in c("borough","open_data_channel_type","problem")) {
  groups <- split(seq_len(nrow(validation)),validation[[v]])
  z <- do.call(rbind,lapply(names(groups),function(g) {
    ix <- groups[[g]]; if(!length(ix)) return(NULL)
    data.frame(category=g,n=length(ix),actual_slow=mean(validation$slow[ix]),
               mean_probability=mean(prob[ix]),flag_rate=mean(prob[ix]>=.25))
  }))
  save_table(z,paste0("validation_risk_",v))
}

# Q26-Q31 Evidence and reproducibility for recommendations and tool reflection.
save_table(data.frame(unique_key=validation$unique_key,actual_hours=validation$resolution_hours,
                      actual_log=validation$log_resolution_hours,predicted_log=pred_valid,predicted_hours=pred_hours,
                      actual_slow=validation$slow,slow_probability=prob,flag=as.integer(prob>=.25)),"validation_predictions")
saveRDS(list(linear=linear,logistic=logistic,maps=maps,thresholds=thresholds,
             global_q75=global_q75,predictors=predictors,smearing=smearing),"analysis/models.rds")
write.csv(train[,c(predictors,"log_resolution_hours","slow")],"analysis/training_model_data.csv",row.names=FALSE)
write.csv(validation[,c(predictors,"log_resolution_hours","slow")],"analysis/validation_model_data.csv",row.names=FALSE)

