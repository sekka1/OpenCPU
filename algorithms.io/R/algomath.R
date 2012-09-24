#' Gets the Factors
#' 
#' @param number the number you wish to factorize
#' @return the factors of the number
#' @author Robert I.
#' @export
findFactorsFor <- function( number )
{
	require(conf.design)
	return (factorize(number));
}