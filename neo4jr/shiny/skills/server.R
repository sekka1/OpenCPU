library(shiny)
library("tm")
library("RWeka")
library("wordcloud")

load(file="skills.rda")
if (!exists("marketskills")) {
  marketskills <- queryCypher2("match m:Market-[:HAS_MARKET]-f:EmploymentFirm-[:HAS_EMPLOYMENT_FIRM]-j-[:HAS_EMPLOYMENT]-p-[:HAS_SKILL]-s where m.display_name! <> \"\" return m.display_name!, s.display_name!")
  names(marketskills) <- c("market", "skill") 
  save(marketskills, file="skills.rda")
}
skillsByMarket <- by(data=marketskills, INDICES=marketskills$market, data.frame)
markets <- unique(marketskills$market)

# Define server logic required to plot various variables against mpg
shinyServer(function(input, output) {
  
  jobTitle <- reactive({ input$jobTitle })
  
  # Return the formula text for printing as a caption
  #   output$caption <- renderText({
  #     input$titlehint1
  #   })
  
  market <- reactive({
    input$market
  })
  
  output$studentCountPlot <- renderPlot({
    oneMarket <- skillsByMarket[grep(market(), names(skillsByMarket))][[1]]   
    corpus <- tm_map(x=Corpus(DataframeSource(as.data.frame(oneMarket[,2]))), FUN=removeWords, stopwords("english"))
    corpus <- tm_map(x=corpus, FUN=removeWords, c("development", "business", "strategy") )
    tdm <- TermDocumentMatrix(corpus)
    print(tdm)
    wordFreq <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)
    wordcloud(words=names(wordFreq), freq=wordFreq, min.freq=3, random.order=F, colors=brewer.pal(8, "Dark2"))
    
  })
})