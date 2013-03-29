
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

#' Preprocess the input datasets to do some common manipulations.
#' @param dataset
#' @param columnNameToTypeMap overrides to columnNameToMap
preProcess <- function(dataset, columnNameToTypeMap=NULL) {
    if (is.character(dataset)) { dataset <- read.csv(dataset); } else { dataset <- data.frame(dataset) }
    dataset <- convertTypes(dataset, columnNameToTypeMap);
    dataset <- data.frame(row.names=1, dataset)
    return(dataset);
}

#' Find anomalies in dataset
#' @param dataset
#' @param top at most number of outliers returned 
#' @param num.sd number of standard deviations 
#' @param method distance measure used
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
findAnomaliesBruteForce <- function(dataset, top=10, num.sd=10, columnNameToTypeMap=NULL, ...) {
    dataset = preProcess(dataset, columnNameToTypeMap);
    m = as.matrix(dist(dataset))
    score = head(sort(rowSums(m),decreasing=TRUE),top)
    results = merge(score, dataset[rownames(dataset) %in% names(score),], by=0, all=TRUE)
    return(results)
}

