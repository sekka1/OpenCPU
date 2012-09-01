#' The trueParams are ALWAYS CORRECT, its the functions real parameters
#' ourParams may be wrong and if so this will throw errors
validateCall <- function( symbolName, ourParams, debug = 0) 
{
	if (length(remove.args(ourParams,symbolName)))
	{
		debugMessage <<- c(debugMessage,"Warning unused arguments removed");
		debugMessage <<- c( debugMessage, remove.args(ourParams,symbolName ));
	}
}

#' Lists all your datafiles from the Data Warehouse
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param algoServer The server you have your files on by default its,https://v1.api.algorithms.io/dataset/
#' @param type string algoServer
#' @return A list of files you have on our servers
#' @author Robert I.
#' @export
listFiles <- function( authToken, algoServer= "https://v1.api.algorithms.io/" )
{
	require(RCurl)
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")
	
	algoServer <- paste(algoServer,"dataset",sep="")
	url <- algoServer;

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
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @param algoServer The server you have your files on by default its,https://v1.api.algorithms.io/dataset/id/
#' @param type string algoServer
#' @param debug Use 1 for debugging outputs the datafile contents
#' @param type int debug
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @export
getFile <- function( authToken , datasetID, algoServer = "https://v1.api.algorithms.io/", debug = 0 )
{
	require(RCurl)
	require(digest)
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")
	
	algoServer <- paste(algoServer,"dataset/id/",sep="");
	url <- paste(algoServer,datasetID,sep="");
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

	
	content <<- getBinaryURL(url, curl = curlH, cainfo = CAINFO);
	op <- options(digits.secs=6)
	options(op)
	
	
	destfile = paste("/opt/Data-Sets/Automation/file_",digest(Sys.time(),algo="md5"),sep="");
	
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

	textOutput <<- rawToChar(content);
	indexOfHTTPHeader <- regexpr("\r\n\r\n", textOutput)[1]
	textOutput <<- substr(textOutput,indexOfHTTPHeader + 4,nchar(textOutput));
	
	#if there is an error we stop here
	if ( length( grep('\"error\"',textOutput ) ) != 0 ) stop(textOutput);

	writeLines(textOutput, destfile)
	echoBack <- destfile;
	if (debug != 0 ){
	debugMessage <<- c(debugMessage,readLines(destfile),sep="\n");
	}
	readLines(destfile)
	return(echoBack);
}

#' Gets a datafile from the Data Warehouse and executes the R function then removes the datafile
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @param algoServer The server we are getting the data from, by default its https://v1.api.algorithms.io/dataset/id/
#' @param type string algoServer
#' @param proxyPackage The name of the package your R function is in, you can use yourpackage to test this
#' @param type string proxyPackage
#' @param proxyFunction The name of the function in the package you want to call, you can use yourfunction1 to test this
#' @param type string proxyFunction
#' @param proxyParametersList IN JSON, The parameters that your function takes in, you can use { "foo": "hello world", "bar": 10 } to test this,
#' @param type string proxyParametersList
#' @param additional_dataset IN JSON, The additional datafiles that your R script requires { "dictionaryFile": "1234", "dictionaryFile2": "1235" } to test this,
#' @param type string additional_dataset
#' @return The end-results of your proxyFunction that you called 
#' @author Robert I.
#' @export
openCPUExecute <- function( authToken, datasetID, algoServer = "https://v1.api.algorithms.io/" , proxyPackage, proxyFunction, proxyParametersList, debug = 0, additional_dataset = "{}" )
{	
	require(RJSONIO);
	require(plotrix);
	library(proxyPackage,character.only=TRUE);
	x <- as.list(fromJSON(proxyParametersList)) 
	debugMessage <<- "";
	if (datasetID=="none") {
	fileName <- "none";
	}
	else {
	fileName <- getFile(authToken,datasetID, algoServer, debug);
	}
	
	if (fileName!="none") x['dataFile'] <- fileName;
	
	y <<- as.list(fromJSON(additional_dataset));
	if (length(y)!=0) #files to download
	{	
		for(i in 1:length(y) ) {
			y[[i]] <<- "fileNameHere";
		}
	}
	else {
		print('none happens')
	}


	stop("hi");


	validateCall(proxyFunction, x, debug)
	tryCatch (
	dataHere <<- do.call(proxyFunction,clean.args(x,proxyFunction)), 
	error = function(e){
	#first print out the error then evaluate the input
	debugMessage <- paste(debugMessage,e,sep="");
	},
	finally={

	}
	)

	#then we clean up the file after this
	if ( file.exists(fileName) ){
	file.remove(fileName)
	}

	if (exists("dataHere") && is.null(dataHere) == FALSE) {
	print(dataHere);
	} else {
		if (debug == 1)
		{
			print("dataHere wasn't set so nothing to display");
		}
	}
	if (debug)
	{
		print(debugMessage);
	}
}


#
#
openCPUExecute( "561285e69a626150fd3276e71059bc39", "none", algoServer = "https://v1.api.algorithms.io/", "yourpackage", "yourFunction1", proxyParametersList = '{ "bar":5}', debug = 0, additional_dataset = '{ "foo":"2043", "dataFile":"2043" }' );	
#
#
#




for(i in 1:length(trollin)) {
	print(i);
}
#
#
#