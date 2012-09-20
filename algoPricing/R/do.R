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

#' Create a dynamic model that matches "query" with training set "dataFrame". The model is built dynamically based on what's available in the query
#'
#' @param dataFrame data frame for training set
#' @param dependentVariable the name of the dependent variable (the one we're trying to predict). It should be numeric.
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @param excludeVariables (optional) list of fields that can not be used in the model. Default no variables.
#' @param maxFactorLevels (optional) maximum number of factor levels to be accepted for any variable in the model. Default is 500
#' @param query list containing name="value" for all the known variables in the query
#' @return a list containing the trained model and the adjusted query
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
trainLinear <- function(dataFrame, dependentVariable, inverseVariables=list(), excludeVariables=list(), maxFactorLevels=100, query) {
    formula <- paste("lm(", dependentVariable, "~")
    for (name in names(query)) {
        if (!any(name %in% excludeVariables))  {
        # we want to ignore columns which are not in the maximal model
            if (is.factor(dataFrame[[name]])) {
            # query factor level exists in training data
                if (any(query[[name]] == levels(dataFrame[[name]]))) {
                    if (nlevels(dataFrame[[name]]) > maxFactorLevels) {
                    # First ensure that all factors in dataFrame have <= maxFactorLevels levels
                    # The top maxFactorLevels levels by occurrence count will be retained, + the one in the query
                        newLevels <- names(summary(dataFrame[[name]], maxsum=maxFactorLevels))
                        if (!(query[[name]] %in% newLevels)) {
                            newLevels[[maxFactorLevels]] <- query[[name]]
                        }
                        dataFrame[[name]] <- factor(dataFrame[[name]], levels=newLevels)
                    }
                    query[[name]] <- as.factor(query[[name]])
                    formula <- paste(formula, name, "+")
                } else {
                # else ignore factor
                    warning(paste("Ignoring factor", name, "as it didn't appear in the top",
                                   maxFactorLevels, " levels of the training data"))
                }
            } else if (is.numeric(dataFrame[[name]])) {
                query[[name]] <- as.numeric(query[[name]])
                if (any(inverseVariables == name)) {
                # If variable has inverse relationship, add 1/x
                    formula <- paste(formula, "I(1/", name, ") +")
                } else {
                    formula <- paste(formula, name, "+")
                }
            }
        } else warning(paste("Ignoring variable", name, "as it is to be excluded"))
    }
    formula <- paste(substr(formula, 0, nchar(formula) - 1), ", data=dataFrame)")
    ## At this point, if we had a braincell, we would first check to see if we have a cached trained model corresponding to these parameters
    ## Then fall back on actually creating it. But.. sadly, the said braincell is missing at the moment.
    trained <- list()
    trained$model <- eval(parse(text=formula))
    trained$query <- query
    trained
}

#' Predict value of query using model.
#'
#' @param linearModel trained linear model
#' @param query list containing name="value" for all the known variables in the query
#' @return predicted value with goodness of fit
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
predictLinear <- function(linearModel, query) {
    prediction <- list()
    prediction$value <- predict(linearModel, query)
    prediction$goodnessOfFit <- summary(linearModel)$r.squared
    prediction
}

#' Suggest a price for a query based on training data from sales history.
#' Robert - can you please hook up this function to OpenCPU. Thanks!
#'
#' @param salesDataFile data file containing sales data
#' @param priceColumn column containing price in training data
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @param excludeVariables (optional) list of variables to exclude from model
#' @param query list with names and values of known variables in prospective sale (input parameters for pricing)
#' @return a predicted value
#'
#' @author Rajiv Subrahmanyam
#' @export
priceLinearPericom <- function(salesDataFile, query) {
    sales <- read.csv(salesDataFile)
    columnNameToTypeMap <- list("item_cost"="numeric", "shipped_quantity"="numeric", "quarter_num"="factor", "Ordered_Qty_Extended_Price"="numeric", "unit_selling_price"="numeric")
    sales <- convertTypes(sales, columnNameToTypeMap)
    trained <- trainLinear(dataFrame=sales,
                    dependentVariable="unit_selling_price",
                    inverseVariables="shipped_quantity",
                    excludeVariables=subset(names(sales), subset=!(names(sales) %in% list("Martket_Segment", "Product_Line", "Product_Family", "Technology",
                            "Sold_To", "End_Customer", "Final_Customer", "Internal_Part_number", "quarter_num", "Ordered_Qty_Extended_Price",
                            "shipped_quantity", "ASM_Region", "segment1.Territory", "segment3.Region", "item_cost"))),
                    query=query)
    prediction <- predictLinear(linearModel=trained$model, query=trained$query)
    prediction$value <- max(prediction$value, 0) # negative prices are ridiculous
    prediction
}
# sample invocation:
# priceLinearPericom(salesDataFile="salesOrders_081712.csv", query=list(Martket_Segment = "AUDIO", Product_Line = "Clock n SAW Oscillators", Technology = "CSO SNGL CER CNV", Sold_To = "AVNET EUROPE COMM VA", Internal_Part_number = "FD5000032", quarter_num = "4", Ordered_Qty_Extended_Price = "1960", shipped_quantity = "4000", ASM_Region = "Europe Distributor", item_cost = ".41926"))
