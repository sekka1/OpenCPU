#' Convert columns in dataFrame to types specified by columnNameToTypeMap. Default is convert to factor.
#'
#' @param columnNameToTypeMap a list of columnNames to types, which can be numeric, character, or factor
#' @param dataFrame dataFrame to be modified
#' @return a new dataFrame with the same contents as dataFrame with types converted as specified in columnNameToTypeMap
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
convertTypes <- function(dataFrame, columnNameToTypeMap) {
    tempFrame <- dataFrame
    # TODO: Here validate that "as." + the values of columnNameToTypeMap are indeed allowable functions
    for(columnName in names(dataFrame)) {
        if (columnName %in% names(columnNameToTypeMap)) {
            type <- columnNameToTypeMap[columnName]
            funcName <- paste("as.", type, sep="")
            if (type == "numeric") { # if numeric, delete commas before parsing
                command <- paste('tempFrame[["', columnName,  '"]] <-',  funcName, '(gsub(\',\', \'\', tempFrame[["', columnName, '"]]))', sep="")
            } else {
                command <- paste('tempFrame[["', columnName,  '"]] <-',  funcName, '(tempFrame[["', columnName, '"]])', sep="")
            }
            eval(parse(text=command))
        }
    }
    tempFrame
}

#' Create a formula from the dataframe column names and the response variable
#' @param dataFrame the source dataFrame
#' @param responseVariable the predicted variable
createFormula <- function(dataFrame, responseVariable) {
    names <- names(dataFrame);
    predictors <- names[!(names %in% responseVariable)];
    return(paste(responseVariable,'~',paste(predictors, collapse=' + ')));
}

#' Preprocess the input datasets to do some common manipulations.
#' @param train training dataset
#' @param test testing dataset
#' @param responseVariable the predicted variable
#' @param columnNameToTypeMap overrides to columnNameToMap
preProcess <- function(train, test, responseVariable, columnNameToTypeMap=NULL) {
    columnNameToTypeMap[responseVariable] <- "factor";
    if (is.character(train)) { train <- read.csv(train); }
    if (is.character(test)) { test <- read.csv(test); }
    if (!(responseVariable %in% names)) { stop(paste('Could not find response variable ',responseVariable)); }
    train <- convertTypes(train, columnNameToTypeMap);
    test <- convertTypes(test, columnNameToTypeMap);
    if (!(sum(names(test) %in% names(train)) == ncol(test))) { stop(paste('Test set has different columns than training set')); }
    return(list(train, test));
}

#' Classify test set based on labeled training data using a logistic regression classifier.
#' @param train training dataset
#' @param test testing dataset
#' @param responseVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyLogisticRegression <- function(train, test, responseVariable, columnNameToTypeMap=NULL) {
    preProcessed <- preProcess(train, test, responseVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    if (!(nlevels(train[[responseVariable]]) == 2)) { stop(paste('Logistic regression can only handle 2 classes for response variable')); }
    formula <- createFormula(train, responseVariable);
    formula <- paste('glm(',formula,', data=train, family="binomial")'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test, type="response")
    prediction <- round(prediction) + 1;
    prediction <- levels(train[[responseVariable]])[prediction]
    return(prediction);
}

#' Classify test set based on labeled training data using a decision tree.
#' @param train training dataset
#' @param test testing dataset
#' @param responseVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyDecisionTree <- function(train, test, responseVariable, columnNameToTypeMap=NULL) {
    library(tree)
    preProcessed <- preProcess(train, test, responseVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, responseVariable);
    formula <- paste('tree(',formula,', data=train)'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test)
    prediction <- colnames(prediction)[(apply(prediction, 1, which.max))]
    return(prediction);
}

#' Classify test set based on labeled training data using a neural network.
#' @param train training dataset
#' @param test testing dataset
#' @param responseVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyNeuralNet <- function(train, test, responseVariable, columnNameToTypeMap=NULL, size=10) {
    library(nnet)
    preProcessed <- preProcess(train, test, responseVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, responseVariable);
    formula <- paste('nnet(',formula,', data=train, size=', size,')'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test)
    prediction <- round(prediction) + 1;
    prediction <- levels(train[[responseVariable]])[prediction]
    return(prediction);
}
