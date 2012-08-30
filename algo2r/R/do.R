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
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @export
getFile <- function( authToken , datasetID, algoServer = "https://v1.api.algorithms.io/" )
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
			#print("increasing");
		}
	}

#pre-parse the content to remove the HTTP headers
#000000B0                    0D 0A 0D 0A                          ....
	#
	textOutput <- rawToChar(content);
	indexOfHTTPHeader <- regexpr("\r\n\r\n", textOutput)[1]
	writeLines(substr(textOutput,indexOfHTTPHeader + 4,nchar(textOutput)), destfile)
	echoBack <- destfile;
	return(echoBack);
}

#' Gets a datafile from the Data Warehouse and executes the R function then removes the datafile
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @param proxyPackage The name of the package your R function is in, you can use yourpackage to test this
#' @param type string proxyPackage
#' @param proxyFunction The name of the function in the package you want to call, you can use yourfunction1 to test this
#' @param type string proxyFunction
#' @param proxyParametersList IN JSON, The parameters that your function takes in, you can use { "foo": "hello world", "bar": 10 } to test this,
#' @param type string proxyParametersList
#' @return The end-results of your proxyFunction that you called 
#' @author Robert I.
#' @export
openCPUExecute <- function( authToken, datasetID, algoServer = "https://v1.api.algorithms.io/", proxyPackage, proxyFunction, proxyParametersList )
{	
	require(RJSONIO);
	library(proxyPackage,character.only=TRUE);
	x <- as.list(fromJSON(proxyParametersList)) 
	if (datasetID=="none") {
	fileName <- "none";
	}
	else {
	fileName <- getFile(authToken,datasetID, algoServer);
	}
	if (fileName!="none") x['dataFile'] <- fileName;
	proxyOutput <- do.call(proxyFunction,x);
	print(proxyOutput);

	#then we clean up the file after this
	if ( file.exists(fileName) ){
	file.remove(fileName)
	}
	
	print(dataHere)
}
