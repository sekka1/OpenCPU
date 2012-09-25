#' Returns a Webpage from a URL
#' 
#' @param URL the webpage you want to display
#' @param type string URL
#' @return the text of the page
#' @author Robert I.
#' @export
getWebpage <- function( URL="http://www.google.com/" )
{
	require(RCurl)
	require(XML)
	base_URL = url.exists(URL)

   # Regular HTTP
  if(base_URL) {

     txt = getURL(URL)

	print(txt);
  } else {
	print("page not found");
  }
}

#' Displays the world population from wikipedia
#' 
#' @note This function relies on the number of tables to not change on the
#; wikipage, so it will break in the future.
#' @return a plot of the world population from the most current fetched wikipedia data
#' @author Robert I.
#' @export
displayWorldPopulation <- function()
{
require(ggplot2)
require(XML)
url  <- 'http://en.wikipedia.org/wiki/World_population'
tbls <- readHTMLTable(url, which=5)
countyname_populations <<- tbls[[2]]
percent_populations <<- tbls[[5]]
tmp <- gsub('%','',percent_populations);


df <- data.frame(
   variable = countyname_populations,
   value = as.numeric(tmp)/100
 )
p <- ggplot(df, aes(x = "", y = value, fill = variable)) + 
   geom_bar(width = 1) + 
   coord_polar("y", start=pi / 3) +    #<- read this line!
   opts(title = "Population Percentages by Count")
print(p)
}

#' Find the common elements among a set of 2 or more lists in CSV format
#' 
#' @param CSVFilePath the location to the file on the hard-drive
#' @param type string CSVFilePath
#' @param columnIndices use c(1,2) to evaluate list 1 and 2, use c(1,2,3) to find common elements between list 1,2, and 3 
#' @param type vector columnIndices 
#' @param hasHeader TRUE if there are headers, FALSE if the CSV doesn't have headers
#' @param type vector hasHeader
#' @return common elements between the lists
#' @author Robert I.
#' @export
getIntersectionCSV <- function( CSVFilePath, columnIndices = 1, hasHeader=FALSE )
{
	tbl <- read.csv(CSVFilePath, header=hasHeader )
	ans <- Reduce(intersect, tbl[columnIndices])
	print(ans);
}