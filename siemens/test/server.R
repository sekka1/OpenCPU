library(shiny)
library(rCharts)
library(Epi)
library(reshape2)

# build data frame 
x <- 1:100
df <- data.frame(x, x^2, 2*x)
names(df) <- c("x", "xpower2", "2productx")


shinyServer(function(input, output) {
  
  # generate tabsetPanel with tabPlots with plot of selected type 
  output$plotpanelcontent <- renderUI({ 
    
    if(input$gobutton != 0){
      
      
      # collect tab names 
      tab.names <- vector()
      if(input$checkboxInputx) tab.names <- c(tab.names, "x")
      if(input$checkboxInputxpower2) tab.names <- c(tab.names, "xpower2")
      if(input$checkboxInput2x) tab.names <- c(tab.names, "2productx")
      print(tab.names)
      
      # render tabs
      tabs <- lapply(tab.names, function(tab.name){ 
        # define tabPanel content depending on plot type selection 
        if(input$plottypechoice == "simple")
          tab <- tabPanel(tab.name, plotOutput(paste0("simpleplot", tab.name)))
        else
          tab <- tabPanel(tab.name, showOutput(paste0("rchartplot", tab.name), "morris"))
        return(tab)
      })  
      return(do.call(tabsetPanel, tabs))
    }
  })  
  
  
  # Render simple plots 
  output$simpleplotx <- renderPlot({ 
    print(plot(df[,1], df[,1]))
    plot(df[,1], df[,1]) 
  })
  output$simpleplotxpower2 <- renderPlot({ 
    print(plot(df[,1], df[,2]))
    plot(df[,1], df[,2])   
  })
  output$simpleplot2productx <- renderPlot({ 
    print(plot(df[,1], df[,3]))
    plot(df[,1], df[,3])   
  })
  
  
  # Render rCharts 
  output$rchartplotx <- renderChart({ 
    plot <- mPlot(x="x", y="x", type = "Line", data = df)
    plot$set(dom = "rchartplotx")
    return(plot)
  })
  output$rchartplotxpower2 <- renderChart({ 
    plot <- mPlot(x="x", y="xpower2", type = "Line", data = df)
    plot$set(dom = "rchartplotxpower2")
    return(plot)
  })
  output$rchartplot2productx <- renderChart({ 
    plot <- mPlot(x="x", y="2productx", type = "Line", data = df)
    plot$set(dom = "rchartplot2productx")
    return(plot)
  })
}) 