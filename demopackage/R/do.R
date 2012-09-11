#' Demo for OpenCPU
#' 
#' @param bar_num This is a test number
#' @param type number bar_num
#' @param foo A variable
#' @param type string foo
#' @return the full filepath the file is saved locally to THIS server
#' @author Robert I.
#' @export
numberCounter <- function( foo, bar_num )
{
	temp <- foo;
	temp <- paste(temp,bar_num*bar_num);
	
	dataHere <<- temp;
}