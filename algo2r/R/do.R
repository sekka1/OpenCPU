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
			#print("increasing");
		}
	}

#pre-parse the content to remove the HTTP headers
#000000B0                    0D 0A 0D 0A                          ....
	#
	textOutput <<- rawToChar(content);
	a <- fromJSON(textOutput)
	textOutput <- gsub('\\n', '\n', a[[1]][["data"]])
	
	#indexOfHTTPHeader <- regexpr("\r\n\r\n", textOutput)[1]
	#writeLines(substr(textOutput,indexOfHTTPHeader + 4,nchar(textOutput)), destfile)
	writeLines(textOutput, destfile)
	echoBack <- destfile;
	return(echoBack);
}

#' Gets a datafile from the Data Warehouse and executes the R function then removes the datafile
#' 
#' @param authToken (type=String) your authorization token linked to your user account
#' @param package (type=String) The name of the package your R function is in, you can use yourpackage to test this
#' @param fun (type=String) The name of the function in the package you want to call, you can use yourfunction1 to test this
#' @param datasets (type = named list) The datafiles that your R script requires, eg: list(dictionaryFile="1234", dictionaryFile2="1235" )
#' @param ... arguments to be passed on to the function
#' @return The end-results of your function that you called 
#' @author Robert I.
#' @author Rajiv Subrahmanyam
#' @export
openCPUExecute <- function( authToken, algoServer = "https://v1.api.algorithms.io/" , package, fun, datasets = list(), ...) {
	datasets <- as.list(datasets)
	y <- list()
	for (dataSetName in names(datasets)) {
		y[[dataSetName]] = getFile(datasets[[dataSetName]], authToken, algoServer)
	}
	params <- append(y, list(...))
	library(package,character.only=TRUE);
	proxyOutput <- do.call(fun, params);
	
	#for ( additional_files in y )
	#{
	#	if ( file.exists(additional_files) ){
	#	file.remove(additional_files)
	#	}
	#	else
	#	{
	#		if (debug)
	#		{
	#			print("odd, the additional file is not found");
	#			print(additional_files);
	#		}
	#	}
	#}
}
