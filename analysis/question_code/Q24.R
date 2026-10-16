logistic <- glm(reformulate(predictors,"slow"),
                data=train, family=binomial())
prob <- predict(logistic, newdata=validation,
                type="response")
print(classification_metrics,row.names=FALSE)
cat("Validation AUC:",auc,"\n")
