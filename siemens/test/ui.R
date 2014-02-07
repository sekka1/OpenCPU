library(shiny)
library(Epi)

shinyUI(pageWithSidebar(  
  headerPanel("Header"),  
  
  sidebarPanel(        
    checkboxInput(inputId = "checkboxInputx", label = "function: x", value = TRUE),
    checkboxInput(inputId = "checkboxInputxpower2", label = "function: x^2", value =     FALSE),
    checkboxInput(inputId = "checkboxInput2x", label = "function:  2x", value = FALSE),
    
    actionButton("gobutton","GO!")
  ),
  
  mainPanel(    
    radioButtons("plottypechoice", "Choose plot type", c("simple", "rCharts")),    
    uiOutput("plotpanelcontent")
  )   
))