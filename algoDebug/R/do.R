
#' Gets a datafile from the Data Warehouse
#' 
#' @param authToken your authorization token linked to your user account
#' @param type string authToken
#' @param datasetID The datasetID like rec_1908
#' @param type string datasetID
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @export
getFileLocal <- function( authToken , datasetID )
{
	require(RCurl)
	require(digest)
	CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")

	url <- paste("https://v1.api.algorithms.io/dataset/id/",datasetID,sep="");
	#url <- "http://www.site.com/science2.txt";
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
	
	destfile <- paste("file_",digest(Sys.time(),algo="md5"),sep="");
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

	textOutput <- rawToChar(content);
	indexOfHTTPHeader <- regexpr("\r\n\r\n", textOutput)[1]
	writeLines(substr(textOutput,indexOfHTTPHeader + 4,nchar(textOutput)), destfile)
	echoBack <- destfile;
	return(echoBack);
}
