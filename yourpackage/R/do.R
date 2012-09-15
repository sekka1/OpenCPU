#' Test function for algo2r
#' 
#' @param foo this string is echo'd
#' @param type string foo
#' @param bar this number is echo'd
#' @param type number bar
#' @param dataFile this is the full path to the file
#' @param type string dataFile
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @export
yourFunction1=function(foo,bar,dataFile="none")
{
	tempVar <- "";
	tempVar <- foo;
	tempVar <- paste(tempVar,bar + 5);
	tempVar <- paste(tempVar,dataFile);
	if (dataFile=="none") {
	tempVar <- paste(tempVar,"No datasource was specified in your request, or File Not Found 404");
	} else {
	
	#CRITICAL!!! Even though the datasets can pass a single dataFile, its still treated as a list!
	#this will be very confusing because people will treat all their dataset variables as a single string
	#but its actually a list of a single string!
	for ( singleFile in dataFile)
	{
			con  <- file(singleFile, open = "r")

			mylines <-readLines(con)
			close(con)
			tempVar <- paste(tempVar,mylines);
	}
	}
	dataHere <<- tempVar;
}


#' @return a plot
#' @author Robert I.
#' @export
yourFunction2=function()
{
	x <- seq(from=0,to=6,by=.10)
	y <- sin(x);
	dataHere <<- plot(x,y);	
}
#
#

#' Testing to see if overwriting variables globally has any effect on 
#' successive calls on the same server or not
#' @return testing
#' @author Robert I.
#' @export
yourFunction3=function()
{
	dataHere <<- paste(dataHere,dataHere,dataHere,sep="");
}
#
#