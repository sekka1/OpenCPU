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

#' Cluster dataset using k-means.
#' @param dataset
#' @param centers number of clusters
#' @param maxiter max number of iterations allowed
#' @param measure distance measure used
#' @param columnNameToTypeMap overrides to columnNameToMap
#' @export
clusterKMeans <- function(dataset, centers=3, maxiter=10, measure="euclidean", columnNameToTypeMap=NULL, ...) {
    library(RJSONIO)
    library(amap)
    preprocessed = preProcess(dataset, columnNameToTypeMap);
    clusters = Kmeans(preprocessed, centers=centers, iter.max=maxiter, method=measure)
    return(clusters[c(4,2,1)])
}

