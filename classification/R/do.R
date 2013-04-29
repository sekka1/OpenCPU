
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
#' @param dependentVariable the predicted variable
createFormula <- function(dataFrame, dependentVariable) {
    names <- names(dataFrame);
    predictors <- names[!(names %in% dependentVariable)];
    return(paste(dependentVariable,'~',paste(predictors, collapse=' + ')));
}

#' Preprocess the input datasets to do some common manipulations.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the predicted variable
#' @param columnNameToTypeMap overrides to columnNameToMap
preProcess <- function(train, test, dependentVariable, columnNameToTypeMap=NULL) {
    columnNameToTypeMap[dependentVariable] <- "factor";
    if (is.character(train)) { train <- read.csv(train); } else { train <- data.frame(train) }
    if (is.character(test)) { test <- read.csv(test); } else { test <- data.frame(as.list(test)); }
    if (!(dependentVariable %in% names(train))) { stop(paste('Could not find dependent variable ',dependentVariable)); }
    train <- convertTypes(train, columnNameToTypeMap);
    train <- train[complete.cases(train),];
    test <- convertTypes(test, columnNameToTypeMap);
    test <- test[complete.cases(test),];
    if (!(sum(names(test) %in% names(train)) == ncol(test))) { stop(paste('Test set has different columns than training set')); }
    return(list(train, test));
}

#' Classify test set based on labeled training data using a logistic regression classifier.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyLogisticRegression <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, ...) {
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    if (!(nlevels(train[[dependentVariable]]) == 2)) { stop(paste('Logistic regression can only handle 2 classes for dependent variable')); }
    formula <- createFormula(train, dependentVariable);
    formula <- paste('glm(',formula,', data=train, family="binomial")'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test, type="response")
    prediction <- round(prediction) + 1;
    prediction <- as.character(levels(train[[dependentVariable]])[prediction])
    return(prediction);
}

#' Classify test set based on labeled training data using multinomial logistic regression.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @param size size of hidden layer
#' @export
classifyMultinomialLogisticRegression <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, ...) {
    library(nnet)
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, dependentVariable);
    formula <- paste('multinom(',formula,', data=train)'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test)
    prediction <- as.character(prediction);
    return(prediction);
}

#' Classify test set based on labeled training data using a decision tree.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyDecisionTree <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, ...) {
    library(tree)
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, dependentVariable);
    formula <- paste('tree(',formula,', data=train)'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test)
    prediction <- as.character(colnames(prediction)[(apply(prediction, 1, which.max))])
    return(prediction);
}

#' Classify test set based on labeled training data using a neural network.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @param size size of hidden layer
#' @export
classifyNeuralNet <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, size=10, ...) {
    library(nnet)
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, dependentVariable);
    formula <- paste('nnet(',formula,', data=train, size=', size,')'); 
    model <- eval(parse(text=formula));
    prediction <- predict(model , newdata=test)
    if (nlevels(train[[dependentVariable]]) == 2) { 
        prediction <- round(prediction) + 1;
        prediction <- as.character(levels(train[[dependentVariable]])[prediction])
    } else { prediction <- as.character(colnames(prediction)[(apply(prediction, 1, which.max))]); }
    return(prediction);
}

#' Classify test set based on labeled training data using a neural network.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifyRandomForest <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, ...) {
    library(randomForest)
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, dependentVariable);
    formula <- paste('randomForest(',formula,', data=train)'); 
    model <- eval(parse(text=formula));
    prediction <- as.character(predict(model , newdata=test));
    return(prediction);
}

#' Classify test set based on labeled training data using a support vector machine. 
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
classifySVM <- function(train, test, dependentVariable, columnNameToTypeMap=NULL, ...) {
    library(e1071)
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    formula <- createFormula(train, dependentVariable);
    formula <- paste('svm(',formula,', data=train)'); 
    model <- eval(parse(text=formula));
    prediction <- as.character(predict(model , newdata=test));
    return(prediction);
}

#' Compare the performance of various available classifiers.
#' @param train training dataset
#' @param test testing dataset
#' @param dependentVariable the label column (for training/testing)
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @param algos List of algorithms to compare
#' @return a list whose names are the supplied algorithms and values are the classification %
#' @export
compareClassifiers <- function(train, test, dependentVariable, columnNameToTypeMap=NULL,
       algos=c('MultinomialLogisticRegression', 'DecisionTree', 'NeuralNet', 'RandomForest', 'SVM'), ...) {
    preProcessed <- preProcess(train, test, dependentVariable, columnNameToTypeMap);
    train <- preProcessed[[1]];
    test <- preProcessed[[2]];
    if (!(dependentVariable %in% names(test))) { stop(paste('Could not find dependent variable',dependentVariable,'in test set')); }
    success <- timePerRecord <- vector();
    for (algo in algos) {
        print(paste('Trying ',algo));
        command <- paste('classify',algo,'(train, test, dependentVariable, columnNameToTypeMap, ...)',sep='');
        start <- proc.time()[['elapsed']];
        result <- eval(parse(text=command));
        end <- proc.time()[['elapsed']];
        success[[algo]] <- sum(result == test[[dependentVariable]]) / nrow(test);
        timePerRecord[[algo]] <- (end-start) / nrow(test);
    }
    return(data.frame(algos, success, timePerRecord));
}

#' Split a single dataset into multiple datasets for training and testing by random sampling.
#' @param data filename of the dataset to be split. Each row is treated as one record.
#' @param fraction fraction that goes into the first file The remaining will go into the second file. 0 <= fraction <= 1.
#' @return a vector of size 2 containing the filenames of the first and second file.
#' @export
splitDataSet <- function(data, fraction) {
    if (is.character(data)) {
        dataFileName <- data;
        data <- read.csv(data);
    } else {
        data <- data.frame(data);
        dataFileName <- "data"
    }
    fraction <- as.numeric(fraction);
    trainFileName <- paste(dataFileName, '.train.csv', sep='');
    testFileName <- paste(dataFileName, '.test.csv', sep='');
    if (fraction < 0 || fraction > 1) stop('fraction must be in the range 0 <= fraction <= 1');
    trainSelect <- sample(c(T,F), size=nrow(data), prob=c(fraction, 1-fraction), replace=T);
    train <- data[trainSelect,];
    test <- data[!trainSelect,];
    write.csv(train, trainFileName, row.names=F);
    write.csv(test, testFileName, row.names=F);
    return(c(trainFileName, testFileName));
}
