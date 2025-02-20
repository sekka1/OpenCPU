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
        if (columnName %in% names(columnNameToTypeMap)) type <- columnNameToTypeMap[columnName]
        else type <- "factor"
        funcName <- paste("as.", type, sep="")
        if (type == "numeric") { # if numeric, delete commas before parsing
            command <- paste('tempFrame[["', columnName,  '"]] <-',  funcName, '(gsub(\',\', \'\', tempFrame[["', columnName, '"]]))', sep="")
        } else {
            command <- paste('tempFrame[["', columnName,  '"]] <-',  funcName, '(tempFrame[["', columnName, '"]])', sep="")
        }
        eval(parse(text=command))
    }
    tempFrame
}

#' Train and return a model that matches "query" with training set "dataFrame"
#' Note that the training set is 'intelligently' filtered based on factor variables in the query.
#'
#' @param dataFrame data frame for training set
#' @param dependentVariable the name of the dependent variable (the one we're trying to predict). It should be numeric.
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @param excludeVariables (optional) list of fields that can not be used in the model. Default no variables.
#' @param query list containing name="value" for all the known variables in the query
#' @return a trained model and modified dataFrame
#'
#' @author Rajiv Subrahmanyam
#' @export
trainLinear <- function(dataFrame, query, dependentVariable, inverseVariables=list(), intersectionThreshold=1) {
    # Extract a minimal set of rows from the dataFrame where all terms in the query are present.
    validColumns <- c(dependentVariable)
    numericColumns <- vector()
    orCondition <- "F"
    andCondition <- "T"
    for (queryVar in names(query)) {
        if (is.factor(dataFrame[[queryVar]]) && query[[queryVar]] %in% levels(dataFrame[[queryVar]])) {
            orCondition <- paste(orCondition, " | dataFrame$", queryVar, "== '", query[[queryVar]], "'", sep='')
            andCondition <- paste(andCondition, " & dataFrame$", queryVar, "== '", query[[queryVar]], "'", sep='')
            validColumns <- c(validColumns, queryVar)
        } else if(is.numeric(dataFrame[[queryVar]])) {
            validColumns <- c(validColumns, queryVar)
            numericColumns <- c(numericColumns, queryVar)
        }
    }
    if (orCondition == "F") orCondition <- "T"
    if (andCondition == "T") andCondition <- "F"

    frames <- list(dataFrame[eval(parse(text=andCondition)),validColumns], dataFrame[eval(parse(text=orCondition)),validColumns])
    for (frame in frames) {
        use <- T
        if (nrow(frame) >= intersectionThreshold) {
            for (numCol in numericColumns) {
                use <- use & (sd(frame[[numCol]], na.rm=T) > 0 | mean(frame[[numCol]], na.rm=T) == query[[numCol]])
            }
        } else use <- F
        if (use) { dataFrame <- frame; break }
    }

    dataFrame <- droplevels(dataFrame[complete.cases(dataFrame),])
    validColumns <- Filter(function(x) is.factor(dataFrame[[x]]) && nlevels(dataFrame[[x]]) > 1 || is.numeric(dataFrame[[x]]), validColumns)
    dataFrame <- dataFrame[,validColumns]

    terms <- list()
    for (queryVar in validColumns[validColumns != dependentVariable]) {
        if (is.factor(dataFrame[[queryVar]])) {
            terms <- c(terms, queryVar)
        } else if(is.numeric(dataFrame[[queryVar]])) {
            if (queryVar %in% inverseVariables) terms <- c(terms, paste("I(1/", queryVar, ")"))
            else terms <- c(terms, queryVar)
        } else query[[queryVar]] <- NULL
    }

    minimal <- list()
    minimal$terms <- terms
    minimal$query <- query
    minimal$dataFrame <- dataFrame
    if (length(terms) > 0) {
        formula <- paste("lm(", dependentVariable, "~")
        for (term in terms) formula <- paste(formula,term,"+")
        formula <- paste(substr(formula, 0, nchar(formula) - 1), ", data=dataFrame, na.action='na.omit')")
        minimal$formula <- formula
        minimal$model <- eval(parse(text=formula))
    }
    minimal
}

#' Suggest a price for a query based on training data from sales history.
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
priceLinearComponent <- function(salesDataFile, columnNameToTypeMap=NULL, componentIdColumn=NULL, quantityColumn=NULL,  unitCostColumn=NULL, unitSalesPriceColumn, query) {
    sales <- read.csv(salesDataFile)
    sales <- convertTypes(sales, columnNameToTypeMap)
    # This is required because RJSONIO converts only mixed type collections into list, and the rest to vectors
    query <- as.list(query) 
    query <- convertTypes(query, columnNameToTypeMap)

    trained <- trainLinear(dataFrame=sales,
                    dependentVariable=unitSalesPriceColumn,
                    inverseVariables=quantityColumn,
                    query=query)
    model <- trained$model
    query <- trained$query
    dataFrame <- trained$dataFrame

    price <- list()
    if (!is.null(model)) {
        minValue <- 0
        if (!is.null(componentIdColumn) && !is.null(query$componentIdColumn) && !is.null(unitCostColumn)) {
            minValue <- max(minValue, min(dataFrame$unitCostColumn[dataFrame$componentIdColumn == query$componentIdColumn,]))
        }
        price$value <- max(predict(model, query), minValue)
    } else {
        warning("No model. Returning mean")
        price$value <- mean(dataFrame)
    }
    price
}

#' Suggest a price for a query based on training data from sales history.
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
    price <- priceLinearComponent(salesDataFile = salesDataFile,
                    columnNameToTypeMap = list("item_cost"="numeric", "shipped_quantity"="numeric", "quarter_num"="factor", "Ordered_Qty_Extended_Price"="numeric", "unit_selling_price"="numeric"),
                    componentIdColumn = "Internal_Part_number",
                    quantityColumn = "shipped_quantity",
                    unitCostColumn = "item_cost",
                    unitSalesPriceColumn="unit_selling_price",
                    query=query)
    price$value
}

# sample invocation:
# priceLinearPericom(salesDataFile="../../../../doc/pricing/FULL/salesOrders_081712.csv", query=list(Internal_Part_number = "FD5000032", shipped_quantity = "4000", ASM_Region = "Europe Distributor", item_cost = ".41926"))

# Omitted for now
#    sales$Internal_Part_number <- as.factor(sub("(A$|B$|C$|FA$|FAE$|FB$|FC$|FD$|FF$|FG$|GA$|H$|J$|K$|L$|MA$|NA$|NB$|NC$|ND$|NE$|NF$|NH$|NJ$|NK$|NL$|Q$|S$|T$|U$|V$|W$|ZA$|ZB$|ZD$|ZE$|ZE$|ZF$|ZF$|ZG$|ZH$|ZI$|ZJ$|ZK$|ZL$|ZM$|ZN$|ZP$|ZR$|ZT$|ZX$|XA$|AE$|BE$|CE$|FAE$|FAEE$|FBE$|FCE$|FDE$|FFE$|FGE$|GAE$|HE$|JE$|KE$|LE$|MAE$|NAE$|NBE$|NCE$|NDE$|NEE$|NFE$|NHE$|NJE$|NKE$|NLE$|QE$|SE$|TE$|UE$|VE$|WE$|ZAE$|ZBE$|ZDEZEE$|ZFE$|ZGE$|ZHE$|ZIE$|ZJE$|ZKE$|ZLE$|ZME$|ZNE$|ZPE$|ZRE$|ZTE$|ZXE$|XAE$|AEX$|BEX$|CEX$|FAEX$|FAEEX$|FBEX$|FCEX$|FDEX$|FFEX$|FGEX$|GAEX$|HEX$|JEX$|KEX$|LEX$|MAEX$|NAEX$|NBEX$|NCEX$|NDEX$|NEEX$|NFEX$|NHEX$|NJEX$|NKEX$|NLEX$|QEX$|SEX$|TEX$|UEX$|VEX$|WEX$|ZAEX$|ZBEX$|ZDEX$|ZEEX$|ZFEX$|ZGEX$|ZHEX$|ZIEX$|ZJEX$|ZKEX$|ZLEX$|ZMEX$|ZNEX$|ZPEX$|ZREX$|ZTEX$|ZXEX$|EVB$|XAEX$|\\+.*)", "", as.character(sales$Internal_Part_number)))
