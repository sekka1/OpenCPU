library(shiny)

load(file="skills.rda")
if (!exists("marketskills")) {
    marketskills <- queryCypher2("match m:Market-[:HAS_MARKET]-f:EmploymentFirm-[:HAS_EMPLOYMENT_FIRM]-j-[:HAS_EMPLOYMENT]-p-[:HAS_SKILL]-s where m.display_name! <> \"\" return m.display_name!, s.display_name!")
    names(marketskills) <- c("market", "skill") 
    save(marketskills, file="skills.rda")
}
markets <- unique(marketskills$market)

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel(""),
  
  # Sidebar with controls to select a dataset and specify the number
  # of observations to view
  sidebarPanel(
        selectInput("market", label="Market", choices=markets)
  ),
  
  # Show the caption and plot of the requested variable against mpg
  mainPanel(
    h3(textOutput("caption")),
    plotOutput("studentCountPlot")
  )
))