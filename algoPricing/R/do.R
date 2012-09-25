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
            command <- paste('tempFrame$', columnName,  '<-',  funcName, '(gsub(\',\', \'\', tempFrame$', columnName, '))', sep="")
        } else {
            command <- paste('tempFrame$', columnName,  '<-',  funcName, '(tempFrame$', columnName, ')', sep="")
        }
        eval(parse(text=command))
    }
    tempFrame
}

#' Extract a minimal set of rows from the dataFrame where all terms in the query are present.
#' Implementing this is less trivial than you'd expect, as there are multiple intersection sets to consider.
#'
#' @param dataFrame the data frame
#' @param query the query
#' @return a list containing minimalSet (minimal rows from dataFrame matching terms in query), and filterCondition
extractMinimalFrame <- function(dataFrame, query, dependentVariable, maxFactorLevels) {
    # get just factor terms
    factorTerms <- Filter(function(x) is.factor(dataFrame[[x]]) && query[[x]] %in% levels(dataFrame[[x]]), names(query))
    intersectionFrame <- dataFrame;
    unionFrame <- data.frame();
    for (factorVar in factorTerms) {
        factorValue <- query[[factorVar]]
        if (factorValue %in% levels(dataFrame[[factorVar]])) {
            intersectionFrame <- intersectionFrame[intersectionFrame[[factorVar]] == query[[factorVar]],]
            unionFrame <- rbind(unionFrame, dataFrame[dataFrame[[factorVar]] == query[[factorVar]],])
        } else warning(paste("Ignoring factor", name, "as it didn't appear in the training data"))
    }
    
    # drop unnecessary levels
    if (nrow(intersectionFrame) == 0) dataFrame <- unionFrame
    else dataFrame <- intersectionFrame

    # keep only columns which are in the query and are factors with more than 1 value or numeric
    dataFrame <- droplevels(dataFrame)
    factorTerms <- Filter(function(x) nlevels(dataFrame[[x]]) > 1, factorTerms)
    numericTerms <- Filter(function(x) is.numeric(dataFrame[[x]]), names(query))
    dataFrame <- dataFrame[,c(factorTerms, numericTerms, dependentVariable)]

    # keep only top n levels
    for (factorVar in factorTerms) {
        if (nlevels(dataFrame[[factorVar]]) > maxFactorLevels) {
        # The top maxFactorLevels levels by occurrence count will be retained, + the one in the query
            newLevels <- names(summary(dataFrame[[factorVar]], maxsum=maxFactorLevels))
            if (!(query[[factorVar]] %in% newLevels)) {
                newLevels[[maxFactorLevels]] <- query[[factorVar]]
            }
            dataFrame[[factorVar]] <- factor(dataFrame[[factorVar]], levels=newLevels)
        }
    }

    dataFrame

#    f <- list()
#    for (name in factorTerms) {
#        f <- c(f, paste(name, " == '", query[[name]], "'", sep=''))
#    }
#
#    orConditions <- list()
#    numConditions <- length(f)
#    while (numConditions > 1) {
#        print("f")
#        print(f)
#        intersectionCount <- matrix(data=0, nrow=numConditions, ncol=numConditions)
#        intersectionCondition <- matrix(nrow=numConditions, ncol=numConditions)
#        # find pairs of conditions with intersections
#        for (i in 1:(numConditions-1)) {
#            for (j in (i+1):numConditions) {
#                intersectionCondition[j, i] <- intersectionCondition[i, j] <- paste("(", f[i], "&", f[j], ")")
#                sub <- subset(dataFrame, subset=eval(parse(text=intersectionCondition[i,j])))
#                intersectionCount[j, i] <- intersectionCount[i, j] <- nrow(sub)
#            }
#        }
#    
#        newF <- list()
#        intersectionExists <- which(rowSums(intersectionCount) > 0)
#        for (i in 1:numConditions) {
#            if (i %in% intersectionExists) {
#                for (j in (i+1):numConditions) {
#                    if (j %in% intersectionExists) {
#                        newF <- c(newF, intersectionCondition[i, j])
#                    }
#                }
#            } else orConditions <- c(orConditions, f[i])
#        }
#        print("newF")
#        print(newF)
#        print("orC")
#        print(orConditions)
#        f <- newF
#        numConditions <- length(f)
#    }
}

#' Create a dynamic model that matches "query" with training set "dataFrame". The model is built dynamically based on what's available in the query
#'
#' @param dataFrame data frame for training set
#' @param dependentVariable the name of the dependent variable (the one we're trying to predict). It should be numeric.
#' @param inverseVariables (optional) list of numerical variables that are known to have an inverse relations (1/x). Default is no variables.
#' @param excludeVariables (optional) list of fields that can not be used in the model. Default no variables.
#' @param maxFactorLevels (optional) maximum number of factor levels to be accepted for any variable in the model. Default is 500
#' @param query list containing name="value" for all the known variables in the query
#' @return a trained model and modified dataFrame
#'
#' @author Rajiv Subrahmanyam
#' -- need not be exported @export
trainLinear <- function(dataFrame, dependentVariable, inverseVariables=list(), excludeVariables=list(), maxFactorLevels=100, query) {
    minimalFrame <- extractMinimalFrame(dataFrame, query, dependentVariable, maxFactorLevels)
    terms <- list()
    for (name in names(minimalFrame)) {
        if (!(name %in% c(excludeVariables, dependentVariable)))  {
        # we want to ignore columns which are not in the maximal model
            if (is.factor(minimalFrame[[name]])) {
                terms <- c(terms, name)
            } else if (is.numeric(dataFrame[[name]])) {
                if (any(inverseVariables == name)) terms <- c(terms, paste("I(1/", name, ")"))
                else terms <- c(terms, name)
            } else warning(paste("Ignoring", name, "as it's neither a factor not a number"))
        } else warning(paste("Ignoring variable", name, "as it is to be excluded"))
    }
    formula <- paste("lm(", dependentVariable, "~")
    for (term in terms) {
        formula <- paste(formula,term,"+")
    }

    trained = list()
    trained$trainingSet <- minimalFrame
    if (length(terms) > 0) {
        formula <- paste(substr(formula, 0, nchar(formula) - 1), ", data=minimalFrame)")
        print(formula)
        ## At this point, if we had a braincell, we would first check to see if we have a cached trained model corresponding to these parameters
        ## Then fall back on actually creating it. But.. sadly, the said braincell is missing at the moment.
        trained$model <- eval(parse(text=formula))
    }
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
    sales$Internal_Part_number <- as.factor(sub("(A$|B$|C$|FA$|FAE$|FB$|FC$|FD$|FF$|FG$|GA$|H$|J$|K$|L$|MA$|NA$|NB$|NC$|ND$|NE$|NF$|NH$|NJ$|NK$|NL$|Q$|S$|T$|U$|V$|W$|ZA$|ZB$|ZD$|ZE$|ZE$|ZF$|ZF$|ZG$|ZH$|ZI$|ZJ$|ZK$|ZL$|ZM$|ZN$|ZP$|ZR$|ZT$|ZX$|XA$|AE$|BE$|CE$|FAE$|FAEE$|FBE$|FCE$|FDE$|FFE$|FGE$|GAE$|HE$|JE$|KE$|LE$|MAE$|NAE$|NBE$|NCE$|NDE$|NEE$|NFE$|NHE$|NJE$|NKE$|NLE$|QE$|SE$|TE$|UE$|VE$|WE$|ZAE$|ZBE$|ZDEZEE$|ZFE$|ZGE$|ZHE$|ZIE$|ZJE$|ZKE$|ZLE$|ZME$|ZNE$|ZPE$|ZRE$|ZTE$|ZXE$|XAE$|AEX$|BEX$|CEX$|FAEX$|FAEEX$|FBEX$|FCEX$|FDEX$|FFEX$|FGEX$|GAEX$|HEX$|JEX$|KEX$|LEX$|MAEX$|NAEX$|NBEX$|NCEX$|NDEX$|NEEX$|NFEX$|NHEX$|NJEX$|NKEX$|NLEX$|QEX$|SEX$|TEX$|UEX$|VEX$|WEX$|ZAEX$|ZBEX$|ZDEX$|ZEEX$|ZFEX$|ZGEX$|ZHEX$|ZIEX$|ZJEX$|ZKEX$|ZLEX$|ZMEX$|ZNEX$|ZPEX$|ZREX$|ZTEX$|ZXEX$|EVB$|XAEX$|\\+.*)", "", as.character(sales$Internal_Part_number)))
    query$Internal_Part_number <- sub("(A$|B$|C$|FA$|FAE$|FB$|FC$|FD$|FF$|FG$|GA$|H$|J$|K$|L$|MA$|NA$|NB$|NC$|ND$|NE$|NF$|NH$|NJ$|NK$|NL$|Q$|S$|T$|U$|V$|W$|ZA$|ZB$|ZD$|ZE$|ZE$|ZF$|ZF$|ZG$|ZH$|ZI$|ZJ$|ZK$|ZL$|ZM$|ZN$|ZP$|ZR$|ZT$|ZX$|XA$|AE$|BE$|CE$|FAE$|FAEE$|FBE$|FCE$|FDE$|FFE$|FGE$|GAE$|HE$|JE$|KE$|LE$|MAE$|NAE$|NBE$|NCE$|NDE$|NEE$|NFE$|NHE$|NJE$|NKE$|NLE$|QE$|SE$|TE$|UE$|VE$|WE$|ZAE$|ZBE$|ZDEZEE$|ZFE$|ZGE$|ZHE$|ZIE$|ZJE$|ZKE$|ZLE$|ZME$|ZNE$|ZPE$|ZRE$|ZTE$|ZXE$|XAE$|AEX$|BEX$|CEX$|FAEX$|FAEEX$|FBEX$|FCEX$|FDEX$|FFEX$|FGEX$|GAEX$|HEX$|JEX$|KEX$|LEX$|MAEX$|NAEX$|NBEX$|NCEX$|NDEX$|NEEX$|NFEX$|NHEX$|NJEX$|NKEX$|NLEX$|QEX$|SEX$|TEX$|UEX$|VEX$|WEX$|ZAEX$|ZBEX$|ZDEX$|ZEEX$|ZFEX$|ZGEX$|ZHEX$|ZIEX$|ZJEX$|ZKEX$|ZLEX$|ZMEX$|ZNEX$|ZPEX$|ZREX$|ZTEX$|ZXEX$|EVB$|XAEX$|\\+.*)", "", query$Internal_Part_number)
    dependentVariable <- "unit_selling_price"
    sales <- convertTypes(sales, columnNameToTypeMap)
    trained <- trainLinear(dataFrame=sales,
                    dependentVariable=dependentVariable,
                    inverseVariables="shipped_quantity",
                    query=query)
    if (!is.null(trained$model)) {
        query <- convertTypes(query, columnNameToTypeMap)
        prediction <- predictLinear(linearModel=trained$model, query=query)
        prediction$value <- max(prediction$value, 0) # negative prices are ridiculous
        prediction
    } else {
        warning("No model. Returning mean")
        mean(trained$trainingSet)
    }
}
# sample invocation:
# priceLinearPericom(salesDataFile="salesOrders_081712.csv", query=list(Martket_Segment = "AUDIO", Product_Line = "Clock n SAW Oscillators", Technology = "CSO SNGL CER CNV", Sold_To = "AVNET EUROPE COMM VA", Internal_Part_number = "FD5000032", quarter_num = "4", Ordered_Qty_Extended_Price = "1960", shipped_quantity = "4000", ASM_Region = "Europe Distributor", item_cost = ".41926"))
