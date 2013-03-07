findHotSpots <- function(population, tornadoes, number) {
    longToCol <- function(long) { as.integer((long - xllcorner)/cellsize) + 1 };
    latToRow <- function(lat) { as.integer((lat - yllcorner)/cellsize) + 1 }
    colToLong <- function(col) { xllcorner + cellsize * (col-1/2) };
    rowToLat <- function(row) { yllcorner + cellsize * (row-1/2) }; 

    for (line in gsub(' +', ' <- ', readLines(con=population, n=6))) { eval(parse(text=line)); }
    pop.df <- read.table(population, skip=6, sep=' ', colClasses=c('numeric'))
    pop.mat <- as.matrix(pop.df)[1:nrows,1:ncols]
    
    torn.df <- read.csv(tornadoes)
    magStartEnd <- torn.df[,c(11,16:19)]
    names(magStartEnd) <- c('FScale', 'StartLat', 'StartLong', 'EndLat', 'EndLong')
    
    scaledTornadoData <- data.frame(magStartEnd[,1], lapply(magStartEnd[,c(3,5)], longToCol), lapply(magStartEnd[,c(2,4)], latToRow));
    names(scaledTornadoData) <- c("FScale","ColStart","ColEnd","RowStart","RowEnd");
    scaledTornadoData <- scaledTornadoData[scaledTornadoData$FScale > 0 & scaledTornadoData$ColStart > 0
                         & scaledTornadoData$ColEnd > 0 & scaledTornadoData$RowStart > 0 & scaledTornadoData$RowEnd > 0,]
    
    torn.mat <- mat.or.vec(nrows, ncols)
    for (i in 1:dim(scaledTornadoData)[1]) {
        row <- scaledTornadoData[i,];
        for (x in row$RowStart:row$RowEnd) {
            for(y in row$ColStart:row$ColEnd) {
                torn.mat[x,y] <- torn.mat[x,y] + row$FScale
            }
        }
    }
    
    combined <- torn.mat * pop.mat
    shelters <- data.frame()
    for (i in head(unique(sort(combined, decreasing=T)),n=number)) { shelters <- rbind(shelters, cbind(which(abs(combined-i) < 0.1, arr.ind=T), i)) }
    shelterLatLong <- data.frame(cbind(unlist(lapply(shelters[,1], rowToLat)), unlist(lapply(shelters[,2], colToLong)), shelters[,3]))
    names(shelterLatLong) <- c("Lat", "Long", "Score")
    shelterLatLong
}
# k <- kmeans(shelterLatLong[1:100,1:2], centers=13)
