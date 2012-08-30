#' Returns the factors of a list of numbers
#' 
#' @param dataFile the filename that contains your data, this is automatically filled in for you by our system
#' @param type string dataFile
#' @return the numbers followed by their factors
#' @author Robert I.
#' @export
algoFactor <- function( dataFile="none" )
{
	if (dataFile=="none") stop("You are missing the datafile!");
	require(conf.design)
	require(gsubfn)

	lines <- readLines(dataFile);

	
	indexCut <- regexpr("data\":", lines )[1] + 7;
	parsedLines <- "";
	parsedLines <- substr(lines,indexCut,nchar(lines)-4)
	parsedLines <- strapply(as.vector(parsedLines), "[0-9]+", simplify = rbind) 
	parsedLines <- as.vector(parsedLines,mode="numeric");
	
	temp <- factorize(parsedLines);
	
	dataHere <<- paste(parsedLines,temp,sep=":");
}

#' Returns a random clustered graph
#' 
#'
#' @param dataFile Unused, the filename that contains your data, this is automatically filled in for you by our system
#' @param type string dataFile
#' @return a graph with clusters identified
#' @author http://stat.ethz.ch/R-manual/R-devel/library/stats/html/kmeans.html
#' @export
algoClusterRandom <- function( dataFile="none" )
{
require(graphics)
require(RJSONIO)

# a 2-dimensional example
x <- rbind(matrix(rnorm(100, sd = 0.3), ncol = 2),
           matrix(rnorm(100, mean = 1, sd = 0.3), ncol = 2))
colnames(x) <- c("x", "y")
(cl <- kmeans(x, 2))
plot(x, col = cl$cluster)
points(cl$centers, col = 1:2, pch = 8, cex=2)

# sum of squares
ss <- function(x) sum(scale(x, scale = FALSE)^2)

## cluster centers "fitted" to each obs.:
fitted.x <- fitted(cl);  
tmp <- "";
tmp <- paste(tmp,toJSON(head(fitted.x)),sep="")
resid.x <- x - fitted(cl)

## Equalities : ----------------------------------
cbind(cl[c("betweenss", "tot.withinss", "totss")], # the same two columns
         c(ss(fitted.x), ss(resid.x),    ss(x)))
stopifnot(all.equal(cl$ totss,        ss(x)),
	  all.equal(cl$ tot.withinss, ss(resid.x)),
	  ## these three are the same:
	  all.equal(cl$ betweenss,    ss(fitted.x)),
	  all.equal(cl$ betweenss, cl$totss - cl$tot.withinss),
	  ## and hence also
	  all.equal(ss(x), ss(fitted.x) + ss(resid.x))
	  )


kmeans(x,1)$withinss # trivial one-cluster, (its W.SS == ss(x))

## random starts do help here with too many clusters
## (and are often recommended anyway!):
cl <- kmeans(x, 5, nstart = 25);
plot(x, col = cl$cluster);
points(cl$centers, col = 1:5, pch = 8)
dataHere <<- cl;
}

#' Returns a clustered Graph
#' 
#'
#' @param numClusters the Number of Clusters you want minimum is 1
#' @param type string numClusters
#' @param dataFile Unused, the filename that contains your data, this is automatically filled in for you by our system
#' @param type string dataFile
#' @return a graph with clusters identified
#' @author Robert I.
#' @export
algoClusterData <- function( numClusters, dataFile="none" )
{
require(algoDebug)
require(graphics)
require(RJSONIO)

dataFile <- getFileLocal("561285e69a626150fd3276e71059bc39","2044");
lines <- readLines(dataFile);

indexCut <- regexpr("data\":", lines )[1] + 7;
	parsedLines <- "";
	parsedLines <- substr(lines,indexCut,nchar(lines)-4)
print(parsedLines);

#split the string up by the \\r\\n first then we have to split again by the commas
	#yes the \r\n became literal backslashes, so you have to \\\\r\\\\n
  	parsedLines <- strsplit(parsedLines,"\\\\r\\\\n")
	parsedLines  <- unlist(parsedLines);
	parsedLines <- strsplit(parsedLines,",");

	#last we need to make it a numeric and not character
	parsedLines <- as.vector(unlist(parsedLines),mode="numeric");
	parsedLines <<- na.omit(parsedLines);
first_col <- parsedLines[seq(1, length(parsedLines), 2)]
sec_col   <- parsedLines[seq(2, length(parsedLines), 2)]

x <- rbind(matrix(first_col,ncol=2),
		matrix(sec_col,ncol=2),
		matrix(sec_col,ncol=2))

colnames(x) <- c("x", "y", "z")
(cl <- kmeans(x, numClusters))
plot(x, col = cl$cluster)
points(cl$centers, col = 1:3, pch = 8, cex=2)
}

algoClusterData (3);
#
#