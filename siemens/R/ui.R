## ui.R
require(rCharts)
shinyUI(pageWithSidebar(
  headerPanel(
    img(src="Siemens.png"),
    verbatimTextOutput("Siemens b.Data Analytics")
  ),
  
  sidebarPanel(

    selectInput(inputId = "agg_var", label = "Select aggregate time series", 
                choices = c("Strom00", "Produkt00", "Erdgas00"),
                multiple = FALSE),
    
    tags$body(
      tags$style(type="text/css", "select[multiple], select[size] { height: 200pt; }")
    ),
    
    selectInput(inputId = "cor_var", label = "Select time series:", choices = signalnames(), 
                multiple = TRUE),
    
    sliderInput(inputId = "forecast_months", label = "Choose months to forecast:", 
                min=1, max=24, value=12),
    
    sliderInput(inputId = "forecast_confidence", label = "Choose confidence level of forecast:", 
                min = .65, max = .95, value = 0.90, step= 0.05)
  ),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Plot",
        h4("Insight"),
        verbatimTextOutput("plot_summary"),
        showOutput("myChart", "morris")
      ),
      tabPanel("Aggregate",
        h4("Insight"),
        verbatimTextOutput("aggregate_summary"),
        showOutput("aggregate", "nvd3")
      ),
      tabPanel("Correlation", 
               h4("Insight"),
               verbatimTextOutput("correlation_summary"),
               showOutput("correlation", "polycharts"),
               plotOutput("scatter")
      ),
      tabPanel("Forecast",         
               h4("Insight"),
               verbatimTextOutput("forecast_summary"),
               plotOutput("forecast")
      )
    )
  )  
))
