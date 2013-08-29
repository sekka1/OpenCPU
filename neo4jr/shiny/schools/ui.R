library(shiny)

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel(""),
  
  # Sidebar with controls to select a dataset and specify the number
  # of observations to view
  sidebarPanel(
#     selectInput("jobTitle", label="Job Title", 
#                 choices=list("ceo", "cto"))
    textInput("jobTitle", label="Job Title", value="founder")  
  ),
  
  # Show the caption and plot of the requested variable against mpg
  mainPanel(
    h3(textOutput("caption")),
    plotOutput("studentCountPlot")
  )
))