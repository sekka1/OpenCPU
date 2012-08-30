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
	tempVar <- c(foo);
	tempVar <- c(tempVar,bar + 5);
	tempVar <- c(tempVar,dataFile);
	if (dataFile=="none") {
	tempVar <- c(tempVar,"No datasource was specified in your request, or File Not Found 404");
	} else {
	lines <-readLines(dataFile)
	tempVar <- c(tempVar,lines);
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