require(rCharts)
require(shiny)

if (file.exists("~/git/opencpu/siemens/data/month_data.rda")) {
  load(file="~/git/opencpu/siemens/data/month_data.rda")
}
if (file.exists("~/git/opencpu/siemens/data/month_series.rda")) {
  load(file="~/git/opencpu/siemens/data/month_series.rda")
}
if (!exists("mdf") || !exists("mts")) {
  print("Creating datasets from files ......")
  mdf <- loadMonthUsageData()
  save(mdf, file="~/git/opencpu/siemens/data/month_data.rda")

  mts <- append(
    lapply(FUN=function(signal) create_month_timeseries(paste0("~/git/opencpu/siemens/data/e_BSP_",signal,".txt")), signalnames()),
    lapply(FUN=function(signal) createTimeSeries(paste0("~/git/opencpu/siemens/data/e_BSP_",signal,".txt")), c("Produkt00", "Produkt01", "Produkt02"))
  )
  save(mts, file="~/git/opencpu/siemens/data/month_series.rda")

  print("Complete")
}

shinyServer(function(input, output) {
  
  source('siemens-package.R', local = TRUE)

#   output$myChart <- renderChart({
#     names(iris) = gsub("\\.", "", names(iris))
#     p1 <- rPlot(input$x, input$y, data = iris, color = "Species", 
#                 facet = "Species", type = 'point')
#     p1$addParams(dom = 'myChart')
#     return(p1)
#   })

  output$forecast_summary <- renderText({
    
    if (length(input$cor_var) > 0)
      paste0("This chart shows the forecast of ", input$cor_var[[1]], " in the future ", input$forecast_months, " months\n",
             "at a confidence level of ", input$forecast_confidence * 100, " percent")
  })

  output$forecast <- renderPlot(function() {
    ts <- mts[[match(input$cor_var, append(signalnames(),signalnames2()))[1]]]
    plot <- HWplot(ts, n.ahead=input$forecast_months, CI=input$forecast_confidence)
    print(plot)
  })

  output$aggregate_summary <- renderText({
    
    if (length(input$cor_var) > 0)
      paste("This chart shows what's missing in the aggregate time series", 
            input$agg_var, 
            "\n",
            "The missing component is shown as top portion of the bars")
    
#     doc <- tags$html(
#       tags$head(
#         tags$title('My first page')
#       ),
#       tags$body(
#         h1('My first heading'),
#         p('My first paragraph, with some ',
#           strong('bold'),
#           ' text.'),
#         div(id='myDiv', class='simpleDiv',
#             'Here is a div with some attributes.')
#       )
#     )
#     return(doc)
  })

  output$aggregate <- renderChart(function() {
    
    # Piechart
#     means <- as.data.frame(sapply(mdf[,input$cor_var], mean))
#     means$signal <- row.names(means)
#     colnames(means) <- c("value", "signal")
#     plot <- nPlot(value ~ signal, data = means, type = 'pieChart')

    # Stacked bar chart
#   mdf <- within(mdf, Missing <- Strom00 - Strom01 - Strom02 - Strom03 - Strom04 - Strom05 - Strom06)
    mdf <- eval(parse(text=paste0('within(mdf, Missing <- ', 
                                 paste(input$agg_var), ' - ', 
                                 paste(input$cor_var, collapse=" - "), 
                                 ')')))
    mdf$date <- format(mdf$TIMESTAMP, "%Y-%m-%d")
    mdf_melted <- eval(parse(text=paste0("melt(mdf[,c('", paste(input$cor_var, collapse="','"), "','Missing','date')], id='date')")))
    plot <- nPlot(value ~ date, group = "variable", data=mdf_melted, type="multiBarChart", showControl=FALSE)
    plot$set(dom = "aggregate")
    return(plot)
  })
  
  output$plot_summary <- renderText({
    if (length(input$cor_var) > 0)
      return(paste("Here's a time series plot for",
                   paste(input$cor_var, collapse=",")))
  })

  output$myChart <- renderChart({
    mdf$date <- format(mdf$TIMESTAMP, "%Y-%m-%d")
    plot <- mPlot(x = "date", y = input$cor_var, 
               type = "Line", data = mdf)
    plot$set(dom = "myChart")
    return(plot)
  })

  output$correlation_summary <- renderText({
    if (length(input$cor_var) > 0) {
      cor.test.res <- lapply(mdf[, input$cor_var], function(x) lapply(mdf[, input$cor_var], function(y) {
        z<-cor.test(x,y)$estimate 
        if (abs(z) > 0.8) {
          return (z)
        }
      })) # lapply                                                                                                                                                                     if (z > 0.8) {return (z)}}))
    } # if
    unlisted <- unlist(cor.test.res)
    unlisted <- unlisted[-grep("(.*)\\.\\1", names(unlisted))]
#     names(unlisted) <- sub(pattern="(.*)\\.cor", replacement="\\1", names(unlisted))
    relnames <- lapply(unique(lapply(strsplit(sub(pattern="(.*)\\.cor", replacement="\\1", names(unlisted)), split="\\."), sort)),
                       function(x) paste(x, collapse=" and "))
    paste("Found significant correlation in these series: \n", paste(relnames, collapse="\n"))
  })
  
  output$correlation <- renderChart({
    # create inputs and outputs - function in radiant.R
#     statTabPanel("Regression","Correlation",".correlation","correlation", "cor_plotWidth", "cor_plotHeight")
#     ts <- create_month_timeseries("~/git/opencpu/siemens/data/e_BSP_Strom00.txt")
#     HWplot(ts, n.ahead=12)
    
    # correlation matrix example from http://rcharts.io/gallery/
#     corrdata=as.data.frame(cor(mdf[,c(2,3,9,13,16,17,18,19)]))
    corrdata=as.data.frame(cor(mdf[,input$cor_var]))
    corrdata$Variable1=names(corrdata)
    corrdatamelt=melt(corrdata,id="Variable1")
    names(corrdatamelt)=c("Variable1","Variable2","CorrelationCoefficient")
    corrmatplot = rPlot(Variable2 ~ Variable1, color = 'CorrelationCoefficient', data = corrdatamelt, type = 'tile', height = 600)
    corrmatplot$addParams(height = 400, width=800)
    corrmatplot$guides("{color: {scale: {type: gradient2, lower: 'red',  middle: 'white', upper: 'blue',midpoint: 0}}}")
    corrmatplot$guides(y = list(numticks = length(unique(corrdatamelt$Variable1))))
    corrmatplot$guides(x = list(numticks = length(unique(corrdatamelt$Variable2))))
    corrmatplot$set(dom = "correlation")
    return(corrmatplot)
  })

  output$scatter <- renderPlot(function() {
    par(pin=c(1, 1),mai=rep(0.1,4), omi=rep(0.01,4), mar=c(5,4,4,2)) 
    plot <- pairs(mdf[,input$cor_var], lower.panel=panel.lm, upper.panel = panel.cor)
    plot
  })
  
  .correlation <- reactive({
    vars <- input$cor_var
    ret_text <- "Please select two or more variables"
    if(is.null(vars) || length(vars) < 2) return(ret_text)
    # if(is.null(inChecker(c(input$cor_var)))) return(ret_text)
    correlation(input$datasets, input$cor_var, input$cor_type, input$cor_cutoff)
  })
  
  statTabPanel <- function(menu_name, fun_name, rfun_label, fun_label, widthFun = "plotWidth", heightFun = "plotHeight") {
    isolate({ 
      sidebarLayout(
        sidebarPanel(
          # based on https://groups.google.com/forum/?fromgroups=#!topic/shiny-discuss/PzlSAmAxxwo
          div(class = "busy",
              p("Calculation in progress ..."),
              img(src="ajaxloaderq.gif")
          ),
          uiOutput(paste0("ui_",fun_label))
        ),
        mainPanel(
          statPanel(fun_name, rfun_label, fun_label, widthFun, heightFun)
        )
      )
    })  
  }
  
})



