library(shiny)

studentData <- queryCypher2(paste("MATCH (i:Institution)-[:ATTENDED]-(e)-[:HAS_EDUCATION]-(p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment)",
                                  "WHERE i.value! <> \"\"",
                                  "WITH i.value! as school, j.title! as title, count(distinct p) as students",
                                  "RETURN school, students, title"))

# Define server logic required to plot various variables against mpg
shinyServer(function(input, output) {
   
  jobTitle <- reactive({ input$jobTitle })
  
  # Return the formula text for printing as a caption
#   output$caption <- renderText({
#     input$titlehint1
#   })
  
  output$studentCountPlot <- renderPlot({
    df <- aggregateBySchoolNames(studentData[grepl(jobTitle(), studentData$X3),])
    par(las=2, mar=par()$mar + c(0.0, 4, 0.0, 0.0))
    barplot(df$count, names.arg=df$school, horiz=T, col=c("lightblue", "darkorange"))
    title("Crunchbase Profiles by Schools",sub=paste0("\"", jobTitle(), "\""))
  })
})