#' Lists all your datafiles from the Data Warehouse
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @return A list of files you have on our servers
#' @author Robert I.
#' @export
listFiles <- function( authToken )
{
	require(RCurl)
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")

	url <- "https://v1.api.algorithms.io/dataset";

	theheader <- c('authToken' = authToken);

	#note the cookie might cause some trouble with apparmor
	cookie = 'cookiefile.txt'
	curlH = getCurlHandle(
	cookiefile = cookie,
	useragent =  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en - US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
	header = TRUE,
	verbose = TRUE,
	netrc = TRUE,
	maxredirs = as.integer(20),
	followlocation = TRUE,
	ssl.verifypeer = FALSE,
	httpheader = theheader
	)

	content = getURL(url, curl = curlH, cainfo = CAINFO);
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
#' @export
getFile <- function( datasetID, authToken , algoServer = "https://v1.api.algorithms.io/" )
{
	require(RCurl)
	require(RJSONIO)
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")

	algoServer <- paste(algoServer,"dataset/id/",sep="");
	url <- paste(algoServer,datasetID,sep="");
	theheader <- c('authToken' = authToken);

	#note the cookie might cause some trouble with apparmor
	cookie = 'cookiefile.txt'
	curlH = getCurlHandle(
	cookiefile = cookie,
	useragent =  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en - US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
	header = FALSE,
	verbose = TRUE,
	netrc = TRUE,
	maxredirs = as.integer(20),
	followlocation = TRUE,
	ssl.verifypeer = FALSE,
	httpheader = theheader
	)

	
	content <<- getBinaryURL(url, curl = curlH, cainfo = CAINFO);
	op <- options(digits.secs=6)
	options(op)
	
	
	destfile = paste("/opt/Data-Sets/Automation/file_",format(Sys.time(), '%Y%m%d%H%M%S'),sep="");
	
	#destfile <- paste("file_",digest(Sys.time(),algo="md5"),sep="");
	doesFileExist <- file.exists(destfile);
	destfileBase <- destfile;
	i <- sample(1:9000,1,replace=T);
	repeat
	{
		
		destfile <- paste(destfileBase,i,sep="_");
		
		doesFileExist <- file.exists(destfile);
		if (doesFileExist==FALSE) {
			break;
		}
		else {
			i <- sample(1:999999999,1,replace=T)
		}
	}

	textOutput <- gsub('\\n', '\n', fromJSON(rawToChar(content))[[1]][["data"]])
	
	writeLines(textOutput, destfile)
	echoBack <- destfile;
	return(echoBack);
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
    parameters <- as.list(parameters)
    realParams <- list()
    for (parameterName in names(parameters)) {
        parameterDef <- parameters[[parameterName]]
        parameterType <- parameterDef[["datatype"]]
        parameterValue <- parameterDef[["value"]]
        realParams[[parameterName]] <- if (parameterType == "datasource") as.character(lapply(parameterValue, getFile, authToken, algoServer))
                                      else parameterValue
    }
    if (evalType == "static") {
        library(package,character.only=TRUE);
    } else if (evalType == "dynamic") {
        eval(parse(text=package))
    } else {
        stop('evalType must be one of "static", "dynamic"')
    }

    proxyOutput <- do.call(fun, realParams);
}
