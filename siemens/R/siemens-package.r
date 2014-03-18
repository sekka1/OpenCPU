#' siemens
#'
#' @name siemens
#' @docType package

signalnames <- function() {
  c("Strom00", "Strom01", "Strom02", "Strom03", "Strom04", "Strom05", "Strom06", "Strom07", "Strom08", "Strom00C", "Strom00FE",
#     "Produkt00", "Produkt01", "Produkt02",
    "Erdgas00", "Erdgas01", "Erdgas02", "Erdgas03", "Erdgas04",
    "HEL00M",
    "Wasser00",
    "Wetter00")
}

signalnames2 <- function() {
  c("Produkt00", "Produkt01", "Produkt02")
}

#' Load usage data by month
#' @description Load time series data from b.data energy usage sensors and merge them into a single dataframe
#' @return dataframe object of month usage
#'
loadMonthUsageData <- function(path = "./data/") {
  require(plyr)

  # load signals into list of data frames, each stripped to with just date and value columns
  # and then merged into one data frame by date
  df <- Reduce(function(...) merge(..., by=c("MSJO_DATUM")), 
               lapply(FUN=function(signal) 
                 rename(read.table(paste0("~/git/opencpu/siemens/data/e_BSP_",signal,".txt"), 
                                   sep=";", header=T)[,c("MSJO_DATUM", "MSJO_WERT")], 
                        c("MSJO_WERT"=signal)), 
                 append(signalnames(), signalnames2())))

  
  df$TIMESTAMP <- as.POSIXct(df$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S")
#   df <- df[, c("TIMESTAMP", "Produkt00", "Produkt01", "Produkt02", "Strom00C", "Strom00FE", 
#                "Strom00", "Strom01", "Strom02", "Strom03", "Strom04", "Strom05", "Strom06",
#                "Strom07", "Strom08", "Erdgas00", "HEL00M", "Wetter00", "Wasser00")]
  df <- df[order(df$TIMESTAMP),]

  df$Strom00 <- append(diff(df$Strom00),0)
  df$Strom01 <- append(diff(df$Strom01),0)
  df$Strom02 <- append(diff(df$Strom02),0)
  df$Strom03 <- append(diff(df$Strom03),0)
  df$Strom04 <- append(diff(df$Strom04),0)
  df$Strom05 <- append(diff(df$Strom05),0)
  df$Strom06 <- append(diff(df$Strom06),0)
  df$Strom07 <- append(diff(df$Strom07),0)
  df$Strom08 <- append(diff(df$Strom08),0)
  df$Erdgas00 <- append(diff(df$Erdgas00),0)
  df$Erdgas01 <- append(diff(df$Erdgas01),0)
  df$Erdgas02 <- append(diff(df$Erdgas02),0)
  df$Erdgas03 <- append(diff(df$Erdgas03),0)
  df$Erdgas04 <- append(diff(df$Erdgas04),0)
  df$HEL00M <- append(diff(df$HEL00M),0)
  df$Wasser00 <- append(diff(df$Wasser00),0)  
  
#   df <- df[, c("TIMESTAMP", "Produkt00", "Produkt01", "Produkt02", "Strom00C", "Strom00FE", "Strom00_DIFF", "Strom01_DIFF", 
#                "Strom02_DIFF", "Strom03_DIFF", "Strom04_DIFF", "Strom05_DIFF", "Strom06_DIFF", "Strom07_DIFF", 
#                "Strom08_DIFF", "Erdgas00_DIFF", "HEL00M_DIFF", "Wetter00", "Wasser00_DIFF")]
  
  # remove last row which was added to allow proper diff
  df <- df[-nrow(df),]

  return(df)
}

plotAll <- function() {
  df <- load_data()
  par(ask=TRUE)
  plotTimeSeries(melt(df[1:53,c(1,7,8,9,10,11)], id.vars = "TIMESTAMP"), title="Strom00-04")
  plotTimeSeries(melt(df[1:53,c(1, 8,12,13)], id.vars = "TIMESTAMP"), title="Strom01,05,06")
  par(ask=FALSE)
}

plotTimeSeries <- function(df, title) {
  ggplot(df, aes(x = TIMESTAMP, y = value, colour = variable)) + geom_line(size=1.5) + geom_point(size=3) + theme(axis.text.x = element_text(angle=60, hjust=1, size=15), axis.text.y = element_text(size=15), axis.title.x = element_text(size=20), legend.title=element_text(colour="blue", size=20), legend.text = element_text(size=15), plot.title=element_text(size=30)) + ggtitle(title)
}

basic_plot <- function(strom=NULL) {
  library(ggplot2)
  ggplot(strom, aes(x=strom$timestamp, y=append(0, diff(strom$MSJO_WERT)))) + geom_line()
}

create_month_timeseries <- function(file) {
  strom <- read.table(file, sep=";", header=T)
  strom$USAGE <- append(0, diff(strom$MSJO_WERT))
  strom$timestamp <- as.POSIXct(strom$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S") 
  strom$MONTH <- strftime(strom$timestamp, "%Y-%m")
  month_usage <- aggregate(strom$USAGE, by=list(strom$MONTH), FUN=sum)
  month_timeseries <- ts(month_usage$x, start=c(2009,1), frequency=12, end=c(2013, 5))
  return(month_timeseries)
}

#' Load data and create time series
createTimeSeries <- function(file) {
  df <- read.table(file, sep=";", header=T)
  df$dt <- as.POSIXct(df$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S") 
  ts <- ts(df$MSJO_WERT, start=c(2009,1), frequency=12, end=c(2013, 6))
  return(ts) 
}

analyseStromSeries <- function(file) {
  par(ask=TRUE)
  ts <- create_month_timeseries(file)
  acf(ts, lag.max=20)
  pacf(ts, lag.max=20)
  summary(auto.arima(ts))
  plot(forecast(auto.arima(ts), h=20))
  plot(HoltWinters(ts))
  plotForecastErrors(forecast.HoltWinters(HoltWinters(ts), h=20)$residuals)
  plot(forecast.HoltWinters(HoltWinters(ts), h=20))
  HWplot(ts, n.ahead=12)
  par(ask=FALSE)
}

getElectricityUsage <- function() {
  strom <- read.table("data/e_BSP_Strom00.txt", sep=";", header=T)
  strom$USAGE <- append(0, diff(strom$MSJO_WERT))
  strom$timestamp <- as.POSIXct(strom$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S") 
  strom$MONTH <- strftime(strom$timestamp, "%Y-%m")
  month_usage <- aggregate(strom$USAGE, by=list(strom$MONTH), FUN=sum)
  names(month_usage) <- c("Monat", "Strom")
  return(month_usage)
}
  
getWaterUsage <- function() {
  wasser <- read.table("data/e_BSP_Wasser00.txt", sep=";", header=T)
  wasser$USAGE <- append(0, diff(wasser$MSJO_WERT))
  wasser$timestamp <- as.POSIXct(wasser$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S")
  wasser$MONTH <- strftime(wasser$timestamp, "%Y-%m")
  month_usage <- aggregate(wasser$USAGE, by=list(wasser$MONTH), FUN=sum)
  names(month_usage) <- c("Monat", "Wasser")
  return(month_usage)
}

#' Create a data frame from input file
#' @description Create a data frame object from input file
getDataByMonth <- function(file, variable="Value", dif=T) {
  df <- read.table(file, sep=";", header=T)
  if (dif) {
    df$USAGE <- append(0, diff(df$MSJO_WERT))
  }
  else {
    df$USAGE <- df$MSJO_WERT
  }
  df$timestamp <- as.POSIXct(df$MSJO_DATUM, format="%d.%m.%Y %H:%M:%S")
  df$MONTH <- strftime(df$timestamp, "%Y-%m")
  month_usage <- aggregate(df$USAGE, by=list(df$MONTH), FUN=sum)
  names(month_usage) <- c("Monat", variable)
  return(month_usage)
}

#' Create a usage plot with rCharts
#' 
plot1 <- function() {
  require(rCharts)
  wasser <- getDataByMonth("data/e_BSP_Wasser00.txt", "Wasser")
  strom <- getDataByMonth("data/e_BSP_Strom00.txt", "Strom")
  produkt <- getDataByMonth("data/e_BSP_Produkt00.txt", "Produkt", dif=F)
  month_usage <- merge(wasser, produkt)
  month_usage <- merge(month_usage, strom)
  ## Need to scale this series to make the chart look better
  month_usage$Strom <- sapply(month_usage$Strom, function(x) x/100)
  mPlot(x = "Monat", y = c("Produkt", "Strom"), type = "Line", data = month_usage[-1,])
}

panel.cor <- function(x, y, digits=2, prefix="", cex.cor, ...) { 
  usr <- par("usr")
  on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- cor(x, y, use="complete.obs")
  txt <- format(c(r, 0.123456789), digits=digits)[1] 
  txt <- paste(prefix, txt, sep="") 
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt) 
  text(0.5, 0.5, txt, cex = cex.cor * (1 + abs(r)) / 2)
}


panel.lm <- function (x, y, col = par("col"), bg = NA, pch = par("pch"), cex = 1, col.smooth = "black", ...) {
  points(x, y, pch = pch, col = col, bg = bg, cex = cex)
  abline(stats::lm(y ~ x),  col = col.smooth, ...)
}

playback <- function() {
  df <- load_data()
  par(ask=TRUE)
  pairs(df[,c(7,8,9,10,11)], lower.panel=panel.lm, upper.panel = panel.cor)
  pairs(df[,c(8,12,13,14,15)], lower.panel=panel.lm, upper.panel = panel.cor)
  ggplot(melt(df[-1,c(1, 7,8,9,10,11)], id.vars = "TIMESTAMP"), aes(x = TIMESTAMP, y = value, colour = variable)) + geom_line()
  pie(c(means[8:13], StromX = means[7] - sum(means[8:13])))
  par(ask=FALSE)
}

plotForecastErrors <- function(forecasterrors)
{
  # make a histogram of the forecast errors:
  mybinsize <- IQR(forecasterrors)/4
  mysd   <- sd(forecasterrors)
  mymin  <- min(forecasterrors) - mysd*5
  mymax  <- max(forecasterrors) + mysd*3
  # generate normally distributed data with mean 0 and standard deviation mysd
  mynorm <- rnorm(10000, mean=0, sd=mysd)
  mymin2 <- min(mynorm)
  mymax2 <- max(mynorm)
  if (mymin2 < mymin) { mymin <- mymin2 }
  if (mymax2 > mymax) { mymax <- mymax2 }
  # make a red histogram of the forecast errors, with the normally distributed data overlaid:
  mybins <- seq(mymin, mymax, mybinsize)
  hist(forecasterrors, col="red", freq=FALSE, breaks=mybins)
  # freq=FALSE ensures the area under the histogram = 1
  # generate normally distributed data with mean 0 and standard deviation mysd
  myhist <- hist(mynorm, plot=FALSE, breaks=mybins)
  # plot the normal curve as a blue line on top of the histogram of forecast errors:
  points(myhist$mids, myhist$density, type="l", col="blue", lwd=2)
}

HWplot<-function(ts_object,  n.ahead=4,  CI=.95,  error.ribbon='green', line.size=1) {
  require(ggplot2)
  require(reshape)
  
  hw_object<-HoltWinters(ts_object) 
  forecast<-predict(hw_object,  n.ahead=n.ahead,  prediction.interval=T,  level=CI)
  for_values<-data.frame(time=round(time(forecast),  3),  value_forecast=as.data.frame(forecast)$fit,  dev=as.data.frame(forecast)$upr-as.data.frame(forecast)$fit)
  fitted_values<-data.frame(time=round(time(hw_object$fitted),  3),  value_fitted=as.data.frame(hw_object$fitted)$xhat)
  actual_values<-data.frame(time=round(time(hw_object$x),  3),  Actual=c(hw_object$x))
  
  # trend component
  trend <- decompose(ts_object)$trend
#   trend[is.na(trend)] <- 0
  trend_values <- data.frame(time=round(as.numeric(time(trend)), 3), Trend=as.numeric(as.data.frame(trend)$x))

  graphset<-merge(actual_values,  fitted_values, by='time',  all=TRUE)
  graphset<-merge(actual_values,  trend_values, by='time',  all=TRUE)
  graphset<-merge(graphset,  for_values,  all=TRUE,  by='time')
  graphset[is.na(graphset$dev),  ]$dev<-0  
  graphset$Fitted<-c(rep(NA,  NROW(graphset)-(NROW(for_values) + NROW(fitted_values))),  fitted_values$value_fitted,  for_values$value_forecast)
  
  graphset.melt<-melt(graphset[, c('time', 'Actual', 'Fitted', 'Trend')], id='time')
  
  p<-ggplot(graphset.melt,  aes(x=time,  y=value)) + geom_ribbon(data=graphset, aes(x=time, y=Fitted, ymin=Fitted-dev,  ymax=Fitted + dev),  alpha=.2,  fill=error.ribbon) + geom_line(aes(colour=variable), size=line.size) + geom_vline(x=max(actual_values$time),  lty=2) + xlab('Time') + ylab('Value') + opts(legend.position='bottom') + scale_colour_hue('')
  p
  return(p)
  
}

HWchart<-function(ts_object,  n.ahead=4,  CI=.95,  error.ribbon='green', line.size=1) {
  require(ggplot2)
  require(reshape)
  
  hw_object<-HoltWinters(ts_object) 
  forecast<-predict(hw_object,  n.ahead=n.ahead,  prediction.interval=T,  level=CI)
  for_values<-data.frame(time=round(time(forecast),  3),  value_forecast=as.data.frame(forecast)$fit,  dev=as.data.frame(forecast)$upr-as.data.frame(forecast)$fit)
  fitted_values<-data.frame(time=round(time(hw_object$fitted),  3),  value_fitted=as.data.frame(hw_object$fitted)$xhat)
  actual_values<-data.frame(time=round(time(hw_object$x),  3),  Actual=c(hw_object$x))
  
  graphset<-merge(actual_values,  fitted_values,  by='time',  all=TRUE)
  graphset<-merge(graphset,  for_values,  all=TRUE,  by='time')
  graphset[is.na(graphset$dev),  ]$dev<-0  
  graphset$Fitted<-c(rep(NA,  NROW(graphset)-(NROW(for_values) + NROW(fitted_values))),  fitted_values$value_fitted,  for_values$value_forecast)
  
  graphset.melt<-melt(graphset[, c('time', 'Actual', 'Fitted')], id='time')
  
  p<-ggplot(graphset.melt,  aes(x=time,  y=value)) + 
    geom_ribbon(data=graphset, aes(x=time, y=Fitted, ymin=Fitted-dev,  ymax=Fitted + dev),  
                alpha=.2,  fill=error.ribbon) + geom_line(aes(colour=variable), size=line.size) + 
    geom_vline(x=max(actual_values$time),  lty=2) + xlab('Time') + ylab('Value') + opts(legend.position='bottom') + 
    scale_colour_hue('')
  p
  return(p)
  
}



