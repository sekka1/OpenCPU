#' Calls a URL on the API site with the given relative path and action
executeAPICall <- function(authToken, algoServer="https://v1.api.algorithms.io/", relativePath, action=getURLContent, ...) {
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")

	url <- paste(algoServer,relativePath,sep="");
	theheader <- c('authToken' = authToken);
	#note the cookie might cause some trouble with apparmor
	cookie <- 'cookiefile.txt'
	curlH <- getCurlHandle(
	    cookiefile = cookie,
	    useragent =  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en - US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
#	    header = TRUE,
#	    verbose = TRUE,
#	    netrc = TRUE,
	    maxredirs = as.integer(20),
	    followlocation = TRUE,
	    ssl.verifypeer = FALSE,
	    httpheader = theheader
	);
	return(action(url, curl = curlH, cainfo = CAINFO, ...));
}

#' Lists all your datafiles from the Data Warehouse
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @return A list of files you have on our servers
#' @author Robert I.
#' @author Rajiv Subrahmanyam
listFiles <- function( authToken, algoServer="https://v1.api.algorithms.io/" ) {
	content <- executeAPICall(authToken, algoServer, "/dataset");
	print(content);

}

#' Gets a datafile from the Data Warehouse
#' 
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @author Rajiv Subrahmanyam
getFile <- function( datasetID, authToken , algoServer = "https://v1.api.algorithms.io/" ) {
	destfile = paste("/opt/Data-Sets/Automation/",authToken,datasetID,sep="");
	# if (! file.exists(destfile)) { # if file exists, don't re-download it. Datasets never change (atleast for now)
	    content <- executeAPICall(authToken, algoServer, paste("dataset/id/",datasetID,sep=''));
	    textOutput <- rawToChar(content);
	    writeLines(textOutput, destfile)
    # }
	return(destfile);
}

#' Puts a datafile
#' @param file filename to be uploaded
#' @param authToken your authorization token linked to your user account
#' @param algoServer the algo server
#' @return the dataset id
#' @author Rajiv Subrahmanyam
putFile <- function(file, authToken, algoServer = "https://v1.api.algorithms.io/" ) {
	content <- executeAPICall(authToken, algoServer, paste("dataset/",sep=''), action=postForm, theFile = fileUpload(file));
	contentJson <- fromJSON(content);
	print(contentJson[[1]]$data)
	return(contentJson[[1]]$data)
}

#' Gets a datafile from the Data Warehouse and executes the R function then removes the datafile
#' 
#' @param authToken (type=String) your authorization token linked to your user account
#' @param evalType (type=String) one of "static" or "dynamic". If evalType == static, the next argument package is loaded from disk.
#'                 If evalType == dynamic, package is treated as raw program text to be evaluated
#' @param package (type=String) The name of the package your R function is in, you can use yourpackage to test this
#' @param fun (type=String) The name of the function in the package you want to call, you can use yourfunction1 to test this
#' @param parameters (type=List) list of metadata + data regarding parameters to be passed to function. The only required attribute of parameter
#'                   is "value" which contains the value to be passed in. Other attributes are "datatype" and "format". parameters whose datatype
#'                   is "datasource" will be dereferenced (value will be treated as datasource id and that will be downloaded and the filename
#'                   passed to the underlying function
#' @return The end-results of your function that you called 
#' @author Robert I.
#' @author Rajiv Subrahmanyam
#' @export
openCPUExecute <- function(authToken, algoServer = "https://v1.api.algorithms.io/" , evalType = "static", package, fun, parameters = list()) {
    require(RJSONIO);
    require(RCurl);
    proxyOutput <- NULL;
#    tryCatch({
    	parameters <- as.list(parameters)
    	realParams <- list()
	
    	# Any parameters that are datasources need to be downloaded first
    	for (parameterName in names(parameters)) {
        	parameterDef <- as.list(parameters[[parameterName]])
        	parameterType <- parameterDef[["datatype"]]
        	parameterValue <- parameterDef[["value"]]
        	realParams[[parameterName]] <- if (!is.null(parameterType) && parameterType == "datasource")
				           	as.character(lapply(parameterValue, getFile, authToken, algoServer))
                                       	else parameterValue
    	}
	
    	# If static, load the library, else eval the code
    	if (evalType == "static") {
        	library(package,character.only=TRUE);
    	} else if (evalType == "dynamic") {
        	eval(parse(text=package))
    	} else {
        	stop('evalType must be one of "static", "dynamic"')
    	}
	
    	# Execute the function
    	proxyOutput <- do.call(fun, realParams);
	
    	# If output is a vector of valid filenames, upload them and return the list of dataset ids
    	if (is.character(proxyOutput)
        	&& sum(file.exists(proxyOutput)) == length(proxyOutput)) {
        	proxyOutput <- sapply(proxyOutput, putFile,  authToken, algoServer);
    	}
	
#    },
#    warning = function(w) { print(w); },
#    error = function(e) { proxyOutput <- e; print(e) });
    return(proxyOutput);
}
