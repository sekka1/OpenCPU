#' Convert columns in dataFrame to types specified by columnNameToTypeMap.
#'
#' @param columnNameToTypeMap a list of columnNames to types, which can be numeric, character, or factor
#' @param dataFrame dataFrame to be modified
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
convertTypes <- function(dataFrame, columnNameToTypeMap) {
    tempFrame <- dataFrame
    # TODO: Here validate that "as." + the values of columnNameToTypeMap are indeed allowable functions
    for(columnName in names(columnNameToTypeMap)) {
        type <- columnNameToTypeMap[columnName]
        funcName <- paste("as.", type, sep="")
        if (type == "numeric") { # if numeric, delete commas before parsing
            command <- paste('tempFrame$', columnName,  '<-',  funcName, '(gsub(\',\', \'\', tempFrame$', columnName, '))', sep="")
        } else {
            command <- paste('tempFrame$', columnName,  '<-',  funcName, '(tempFrame$', columnName, ')', sep="")
        }
        eval(parse(text=command))
    }
    tempFrame
}

#' Predict value for "query" using training set "dataFrame". The model is built dynamically based on what's available in the query
#'
#' @param dataFrame data frame for training set
#' @param dependentVariable the name of the dependent variable (the one we're trying to predict). It should be numeric.
#' @param query list containing name="value" for all the known variables in the query
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @param maximalModel (optional) list of fields that can be used in a model. If a variable doesn't appear in this list, it won't be used. Default is all the columns in dataFrame.
#' @param maxFactorLevels (optional) maximum number of factor levels to be accepted for any variable in the model. Default is 500
#' @return a predicted value
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
predictLM <- function(dataFrame, dependentVariable, query, inverseVariables=list(), maximalModel=names(dataFrame), maxFactorLevels=500) {
    # First ensure that all factors in dataFrame have <= maxFactorLevels levels
    # The top maxFactorLevels levels by occurrence count will be retained and the others will be replaced with "(Other)"
    for (column in names(dataFrame)) {
        if (is.factor(dataFrame[[column]]) && nlevels(dataFrame[[column]]) > maxFactorLevels) {
            dataFrame[[column]] <- factor(dataFrame[[column]], levels=names(summary(dataFrame[[column]], maxsum=maxFactorLevels)))
        }
    }
    formula <- paste("lm(", dependentVariable, "~")
    for (name in names(query)) {
        if (any(maximalModel == name))  { # we want to ignore columns which are not in the maximal model
            if (is.factor(dataFrame[[name]])) {
                if (any(query[[name]] == dataFrame[[name]])) { # query factor level exists in training data
                    formula <- paste(formula, name, "+")
                } else if (any("(Other)" == dataFrame[[name]])) { # does not exist, but dataFrame has grouped factor "(Other)"
                    query[[name]] <- as.factor("(Other)")
                    formula <- paste(formula, name, "+")
                } else { # else ignore factor
                    warning(paste("Ignoring factor", name, "as it didn't appear in the training data"))
                }
            } else if (is.numeric(dataFrame[[name]])) {
                if (any(inverseVariables == name)) { # If variable has inverse relationship, add 1/x
                    formula <- paste(formula, "I(1/", name, ") +")
                } else {
                    formula <- paste(formula, name, "+")
                }
            }
        } else warning(paste("Ignoring variable", name, "as it is not in the maximal model"))
    }
    formula <- paste(substr(formula, 0, nchar(formula) - 1), ", data=dataFrame)")
    linear.model <- eval(parse(text=formula))
    prediction <- predict(linear.model, query)
}

#' Merge 2 datasets with the given join condition. Does not work!
#'
#' @param dataSet1 first dataset
#' @param dataSet2 second dataset
#' @param columnMapping a list of size 1 with key = column name in dataSet1, value = column name in dataSet2
#' @param joinType one of 'left', 'right'
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
mergeDataSets <- function(dataSet1, dataSet2, dataSet1Column, dataSet2Column, joinType) {
    # TODO: ensure size(columnMapping) == 1
    if (joinType == 'left') { joinCommand <- 'all.dataSet1=true' }
    else if (joinType == 'right') { joinCommand <- 'all.dataSet2=true' }
    col1 <-
    merged <- merge(dataSet1, dataSet2, by.dataSet1=dataSet1Column, by.dataSet2=dataSet2Column, joinCommand)
    merged
}

#' Suggest a price for a query based on training data from sales history.
#' Robert - can you please hook up this function to OpenCPU. Thanks!
#'
#' @param salesDataFile data file containing sales data
#' @param priceColumn column containing price in training data
#' @param query list with names and values of known variables in prospective sale (input parameters for pricing)
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @return a predicted value
#'
#' @author Rajiv Subrahmanyam
#' @export
price <- function(salesDataFile, columnNameToTypeMap, priceColumn, query, inverseVariables) {
    sales <- read.csv(salesDataFile)
    sales <- convertTypes(sales, columnNameToTypeMap)
    prediction <- predictLM(dataFrame=sales,
                    dependentVariable=priceColumn,
                    query=query,
                    inverseVariables=inverseVariables)
}
# example invocation:
# price(salesDataFile="salesOrders_081712.csv", columnNameToTypeMap = list("item_cost"="numeric", "quarter_num"="numeric", "shipped_quantity"="numeric", "quarter_num"="factor", "Ordered_Qty_Extended_Price"="numeric", "unit_selling_price"="numeric"), priceColumn="unit_selling_price", query=list(Product_Line="Clock n SAW Oscillators", Technology="XTL MTL TF", item_cost=1, shipped_quantity=100000, ASM_Region="Europe Distributor"), inverseVariables="shipped_quantity")
