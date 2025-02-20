#' 
#' 
#' 
#' 
queryCypher <- function(querystring) {
  h = basicTextGatherer()
  curlPerform(url="http://localhost:7474/db/data/ext/CypherPlugin/graphdb/execute_query",
              postfields=paste('query',curlEscape(querystring), sep='='),
              writefunction = h$update,
              verbose = FALSE
  )
  
  result <- fromJSON(h$value())
  
  data <- data.frame(t(sapply(result$data, unlist)))
  #names(data) <- result.json$columns
  junk <- c("outgoing_relationships","traverse", "all_typed_relationships","property","self","properties","outgoing_typed_relationships","incoming_relationships","create_relationship","paged_traverse","all_relationships","incoming_typed_relationships")
  data <- data[,!(names(data) %in% junk)] 
  data
}

#' Executes cypher query
#' @description Executes cypher query to Neo4j server instance
#' @param serverURL URL of Neo4j cypher query endpoint.  It should end with db/data/cypher
#' @param querystring Query
#' @export
#' @import RCurl
#' @import RJSONIO
#' @import bitops
#' @examples queryCypher2("match (e)-[:HAS_EMPLOYMENT]->(j) return e,j limit 10")
#'
queryCypher2 <- function(querystring, serverURL="http://166.78.27.160:7474/db/data/cypher") {
  library(RCurl)
  library(RJSONIO)
  library(bitops)
  h = basicTextGatherer()
  curlPerform(url=serverURL,
              postfields=paste('query',curlEscape(querystring), sep='='),
              writefunction = h$update,
              verbose = FALSE
  )
  
  # Alternatively, postForm can be used
  # output <- postForm(serverURL, .opts=list(verbose=TRUE, httpheader=c('Content-Type'='application/json',"Accept"='application/json'), postfields=toJSON(list("query"='match e:Engineer return e limit 10'))))
  # result <- fromJSON(rawToChar(output))
  #
  
  result <- fromJSON(h$value())
  
  if (!is.null(result$exception) && result$exception == "SyntaxException") {
    write(paste(result$fullname, "...\n", result$message), stderr())
    return(NULL)
  }
  
  # Handle single column returned
  if (is.list(result$data) & length(result$data[[1]]) == 1) {
    data <- data.frame(as.matrix(result$data))
    names(data) <- c("X1")
    return (data)
  }
  
  # fromJSON returns lists and if passed to unlist, will produce rows with different number of columns.
  # For instance, 
  # "{\n  \"columns\" : [ \"p.source_uid\", \"d.type\", \"d.institution\" ],\n  \"data\" : [ [ \"niklas-zennstrom\", [ \"msc\", \"bsc\" ], \"uppsala university\" ] ]\n}"
  # will be unlist'ed into
  # Browse[2]> result$data[[1]]
  #   [[1]]
  #   [1] "niklas-zennstrom"
  #   
  #   [[2]]
  #   [1] "msc" "bsc"
  #   
  #   [[3]]
  #   [1] "uppsala university"
  #
  #
  #   Browse[2]> sapply(result$data, unlist)
  #   [,1]                
  #   [1,] "niklas-zennstrom"  
  #   [2,] "msc"               
  #   [3,] "bsc"               
  #   [4,] "uppsala university"
  
  # data <- data.frame(t(sapply(result$data, unlist)))
  
  d <- sapply(result$data, 
              function(x) sapply(x, 
                function(y)
                  if (is.null(y)) NA 
                  # cypher query can return NULL for variables appended with "!" which will cause 
                  # data.frame to have list elements
                  else if (length(y)>1) y<-paste(y, collapse=',') 
                  else y))

  data <- data.frame(t(d))
    
  #names(data) <- result.json$columns
  junk <- c("outgoing_relationships","traverse", "all_typed_relationships","property","self","properties","outgoing_typed_relationships","incoming_relationships","create_relationship","paged_traverse","all_relationships","incoming_typed_relationships")
  data <- data[,!(names(data) %in% junk)] 
  data
#   return(data[,!(names(data) %in% junk)])
}

testQueryCypher2 <- function() {
  library(testthat)
  test_that("single column returned", code={
    df = queryCypher2("match p:PersonGUID return p.source_uid! limit 10")  
    print(df)
    expect_equal(nrow(df), expected=10)
    expect_equal(length(df), expected=1)
  })
  test_that("multiple columns returned", code={
    df = queryCypher2("match p:PersonGUID-[:HAS_EDUCATION]->d return p.source_uid, d.type!, d.institution! limit 10")
    print(df)
    expect_equal(nrow(df), expected=10)
    expect_equal(ncol(df), expected=3)
  })
  test_that("person and degrees", code={
    df = queryCypher2("match p:PersonGUID-[:HAS_EDUCATION]->d return p.source_uid!, d.type!, d.institution!")
    expect_equal(ncol(df), expected=3)
    expect_that(nrow(r[is.na(r$X3),]), condition=
)
  })
}

#'
#'
#'
weightByTitle <- function(title) {
  if (grepl("ceo",title)) {
    0.3;
  }
  else if (grepl("cto",title)){
    .2;
  }
  else if (grepl("architect",title)) {
    .05;
  }
  else if (grepl("coo",title)) {
    .15;
  }
  else if (grepl("president",title)) {
    .2;
  }
  else if (grepl("vp",title)) {
    .1;
  }
  else if (grepl("cpo",title) || grepl("chief product officer",title)) {
    .1;
  }
  else if (grepl("cco",title)) {
    .1;
  }
  else if (grepl("cmo",title)) {
    .1;
  }
  else if (grepl("engineer",title)) {
    .05;
  }
  else if (grepl("advisor",title)) {
    .01;
  }
  else if (grepl("chairman",title)) {
    .15;
  }
  else if (grepl("board member",title) || grepl("board+member",title)) {
    .01;
  }
  else if (grepl("partner",title)) {
    .05;
  }
  else if (grepl("founder+",title)) {
    .1;
  }
  else 
    .01;
}

#' Convert string of total money raised from Crunchbase to a numeric value
#' 
getScore <- function(moneyString) {
  library(gdata)
  if (startsWith(moneyString,"$")) {
    valuestr = valuestr.substring(1);
  }
  else if (startsWith(moneyString,"¥")) {
    valuestr = valuestr.substring(1);
    exchange = .01;
  }
  else if (startsWith(moneyString,"£")) {
    valuestr = valuestr.substring(1);
    exchange = 1.5;
  }
  else if (startsWith(moneyString,"€")) {
    valuestr = valuestr.substring(1);
    exchange = 1.3;
  }
  else if (startsWith(moneyString,"c$")) {
    valuestr = valuestr.substring(2);
  }
  else if (startsWith(moneyString,"kr")) {
    valuestr = valuestr.substring(2);
    exchange = .15;
  }
}

#' Score Crunchbase person profiles  
#' @description Score is based on the total money raised of a company, discounted according to person's job title.  
#' @return a data.frame with columns "person", "coworker" and "score"
#'
scoreCrunchBase <- function(count=10000) {
  library(stringr)
  
  #
  # main dataset query
  query = paste("MATCH (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment)-[:HAS_EMPLOYMENT_FIRM]->(f:EmploymentFirm)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(c:PersonGUID), ",
                "(p:PersonGUID)-[:HAS_EDUCATION]-(e:Education)",
                # By using HAS(), this query does not produce rows with NULL values,
                # As a result, it reduces number of rows available to regression
                # The correct way to produce full dataset with NUll values is to use property! in the RETURN clause
                # TODO(anthony): Fix 
                "WHERE f.total_money_raised! <> \"$0\" AND HAS(p.source_uid) AND HAS(f.value) AND HAS(j.title) AND HAS(e.type) AND HAS(e.institution) AND HAS(c.source_uid)",
                "RETURN p.source_uid, f.value, j.title, e.institution, e.type, c.source_uid, f.total_money_raised",
                (if (count<0) "" else paste("LIMIT",as.integer(count))));
  
  results <- queryCypher2(query);
  names(results) <- c("person", "company", "title", "school", "degree", "coworker", "total_money_raised")

  
  # Add a numeric feature to the school
  results <- scoreSchool(results)

  # Add a numeric feature based on degree description
  results <- scoreDegree(results)
 
  results$score <- sapply(results[,"total_money_raised"], function(x) str_extract(x,"[0-9.]+"))
  exchange <- c("$"=1.0, "¥"=.01, "£"=1.5, "€"=1.3, "c$"=0.95)
  unit <- c("m"=1e6, "k"=1e3, "b"=1e9)
  results[,"score"] <- as.numeric(results[,"score"]) * unit[str_extract(results[,"total_money_raised"], "([^0-9.]+)$")]
  results[,"score"] <- results[,"score"] * sapply(results[,"title"], weightByTitle)
  
  return(results)
}

#'
#' Create igraph from relations
#' @description Create igraph out of all persons in neo4j db
#' @param relations a data.frame with at least 3 columns, person, related and score
#' @export
#'
createGraph <- function(relations) {
  library(igraph)
  library(bitops)
  # related <- queryCypher2(querystring="match (p)-[:HAS_EMPLOYMENT]->j-[:HAS_EMPLOYMENT_FIRM]->(f)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(q) return p.source_uid, q.source_uid limit 100;")
  if (!is.data.frame(relations)) {
    write("relations need to be a dataframe", stderr())
    return
  }
   
  g <- graph.edgelist(as.matrix(relations[,c("person", "coworker")]))
  #E(g)$weight <- relations[,"score"]
  
  #plot.igraph(g)
  g
}

#'
#' #' Run page rank on igraph from CrunchBase
#' @description Run igraph page rank algorithm on graph with scores from Crunchbase data, show the top entries with scores
#' @export
#' 
runPageRank <- function(top=20) {
  persons <- scoreCrunchBase()
  graph <- createGraph(persons)

  # aggregate to get a person's total scores
  personCompanyScore <- aggregate(persons$score, by=list(persons$person, persons$company), FUN=mean)
  personScore <- aggregate(personCompanyScore$x, by=list(personCompanyScore$Group.1), FUN=sum)
  names <- V(graph)$name
  personScoreRightOrder <- merge(data.frame(names), personScore, by.x='names', by.y='Group.1', all.x=T, sort=F)
  vector <- page.rank(graph, personalized=personScoreRightOrder$x)$vector
#  vector <- page.rank(graph)$vector
  head(sort(vector, decreasing=T),n=top)
  vector
}


scoreTitle <- function(titles) {
#   titles$title <- sapply(titles$title, str_trim)
  titles$title_score <- ifelse(grepl(pattern="c\\.?e\\.?o|chief.*ex.*off", titles$title), 10, 0)
  titles$title_score <- ifelse(grepl(pattern=".*president.*|.*coo.*|.*chief.*oper.*", titles$title) & sapply(titles$title_score, function(x) x==0), 6, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern="founder", titles$title) & sapply(titles$title_score, function(x) x==0), 8, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*cto*|chief.*tech|chief.*scientist", titles$title) & sapply(titles$title_score, function(x) x==0), 7, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*architect.*|lead.*engineer", titles$title) & sapply(titles$title_score, function(x) x==0), 2, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*.*v\\.?p\\.?.*", titles$title) & sapply(titles$title_score, function(x) x==0), 3, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*cpo.*|chief.*product.*", titles$title) & sapply(titles$title_score, function(x) x==0), 3, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*chair.*", titles$title) & sapply(titles$title_score, function(x) x==0), 1, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*c\\.?f\\.?o*|chief.*finan", titles$title) & sapply(titles$title_score, function(x) x==0), 7, titles$title_score)
  titles$title_score <- ifelse(grepl(pattern=".*engineer|developer", titles$title) & sapply(titles$title_score, function(x) x==0), 1.5, titles$title_score)
  
  return(titles)
}


#' 
#' Run regression on all persons from CrunchBase
#' @description First query produce all coworker relations, then used to generate pagerank scores
#' Second query creates personal attributes, such as education and work titles, used to compute numeric variables.  
#' Then pagerank scores are added as feature
#' @import igraph
#' 
runRegression <- function(count=1000) {
  library(igraph)
  coworkerQuery = paste("MATCH (p:PersonGUID)-[:HAS_EMPLOYMENT]->j-[:HAS_EMPLOYMENT_FIRM]->(f:EmploymentFirm)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(c:PersonGUID)",
                        "WHERE HAS(p.source_uid) AND HAS(c.source_uid)",
                        "RETURN p.source_uid, c.source_uid",
                        (if (count<0) "" else paste("LIMIT",as.integer(count))));
  relations <- queryCypher2(coworkerQuery)
  names(relations) <- c("person", "coworker")
  pr <- page.rank.old(createGraph(relations))
  prdf <- data.frame(names(pr), pr)
  names(prdf) <- c("person", "pagerank")
  
  # Query for just person' education, what company worked for and title, no relations to other people
  trainQuery = paste("MATCH (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment)-[:HAS_EMPLOYMENT_FIRM]->(f:EmploymentFirm),",
                     "(p:PersonGUID)-[:HAS_EDUCATION]-(e:Education)",
                     "WHERE f.total_money_raised! <> \"$0\" AND HAS(p.source_uid) AND HAS(f.value) AND HAS(j.title) AND HAS(e.type) AND HAS(e.institution)",
                     "RETURN p.source_uid, f.value, j.title, e.institution, e.type, f.total_money_raised",
                     (if (count<0) "" else paste("LIMIT",as.integer(count))));
  training <- queryCypher2(trainQuery)  
  names(training) <- c("person", "company", "title", "school", "degree", "total_money_raised")
  
  training <- weightScoreByTitle(training)
  training <- scoreSchool(training)
  training <- scoreDegree(training)
  training <- scoreTitle(training)
  training <- merge(merge(merge(merge(aggregate(score ~ person, data=training, FUN=sum), aggregate(school_score ~ person, data=training, FUN=max)), aggregate(deg_score ~ person, data=training, FUN=max)), aggregate(title_score ~ person, data=training, FUN=max)), prdf, all.x=T)
  trainingNamesAndScores <- training[,c('person', 'score')]
  training <- training[,c('score', 'school_score', 'deg_score', 'title_score', 'pagerank')]
  
  # Query with all other entries with zero money raised (no score)
  testsetQuery = paste("MATCH (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment),(p:PersonGUID)-[:HAS_EDUCATION]-(e:Education) where HAS(p.source_uid) return p.source_uid, e.institution?, e.type?, j.title?",
                       (if (count<0) "" else paste("LIMIT",as.integer(count))));
  test <- queryCypher2(testsetQuery)  
  names(test) <- c("person", "school", "degree", "title")
  testsetQuery2 = paste("MATCH (p:PersonGUID)-[:HAS_EDUCATION]-(e:Education)",
                    "WHERE HAS(p.source_uid)",
                    "RETURN p.source_uid, e.institution?, e.type?",
                    (if (count<0) "" else paste("LIMIT",as.integer(count))));
  test2 <- queryCypher2(testsetQuery2) 
  names(test2) <- c("person", "school", "degree")
  title <- NA
  test2 <- cbind(test2, title)
  test <- rbind(test, test2)

  test$person <- unlist(test$person)
  known <- unique(training$person)
  test <- test[!(test$person %in% known),]
  test <- scoreSchool(test)
  test <- scoreDegree(test)
  test <- scoreTitle(test)
  test <- merge(merge(merge(aggregate(school_score ~ person, data=test, FUN=max), aggregate(deg_score ~ person, data=test, FUN=max)), aggregate(title_score ~ person, data=test, FUN=max)), prdf, all.x=T)
  testNames <- test$person
  test <- test[,c('school_score', 'deg_score', 'title_score', 'pagerank')]
  o <- data.frame(testNames, regressionLinear(training, test, dependentVariable='score'), decisionTree(training, test, dependentVariable='score', regression=T), SVM(training, test, dependentVariable='score', regression=T), rForest(training, test, dependentVariable='score', regression=T))
  names(o) <- c('person', 'scoreLinearRegression', 'scoreDecisionTree', 'scoreSVM', 'scoreRandomForest')
  score <- (o$scoreLinearRegression + o$scoreSVM + o$scoreRandomForest) / 3
  o<- cbind(o, score)
  o<- rbind(o[,c('person','score')], trainingNamesAndScores)
  o <- filterLawyer(filterInvestor(o))
  return(o)
}



crunchBaseBasicStats <- function(serverURL="http://166.78.27.160:7474/db/data/cypher") {
  queryCypher2("match (p:PersonGUID) return count(p);")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) return count(p);")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) AND HAS(d.graduated_year) return count(p) ;")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) AND HAS(d.graduated_year) AND HAS(d.type) return count(p);")
  queryCypher2("match (d:Degree) return count(d)")  
  # number of institutions
  queryCypher2("match (i:Institution) return length(collect(i.value?))")
  # how many "co-worker" relationships - 4681532 on 8/10/2013
  queryCypher2("MATCH (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment)-[:HAS_EMPLOYMENT_FIRM]->(f:EmploymentFirm)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(c:PersonGUID)  RETURN count(*);")
}

#' 
#' Add a numeric value feature to the data frame
#' @description Adds a new column based on the names of school
#' @param edu input dataset with a column named "school"
#' @return dataset with added column called "school_score"
#' @export
#'
scoreSchool <- function(edu, scores=NULL) {
  if (is.null(scores)) {
    scores <- read.csv(unz(system.file(package="neo4jr", "data/University Rankings 2011 QS.csv.zip"), 
                           "University Rankings 2011 QS.csv"))
#     scores <- read.csv("data/University Rankings 2011 QS.csv")
    scores <- scores[,c("School.Name", "Score")]
  }   
  schoolNames <- tolower(scores$School.Name)
  # try partial match by grep first 
  #edu$school_score <- sapply(edu$school, function(x) ave(scores[grep(str_trim(x),scores$School.Name,ignore.case=T),]$Score)[1])
  edu$school_score <- sapply(edu$school, function(x) ifelse(is.null(x), 0, ave(scores[pmatch(str_trim(x),schoolNames),]$Score)[1]))
  # TODO(anthony): partial match using grep only fills in 50 percent of the scores, fill in the rest as 50 out of 100 as the median
  med <- rep(50, length(edu[is.na(edu$school_score),]$school_score))
  edu[is.na(edu$school_score),]$school_score <- med

  return(edu)
}

#'
#' Add a numeric column to data frame based on degree description
#' 
scoreDegree <- function(degs) {
  sapply(degs$degree, str_trim)
  degs$deg_score <- ifelse(grepl(pattern="m\\.?b\\.?a\\.?", degs$degree) | grepl(pattern=".*mast.*bus", degs$degree), 7, 0)
  degs$deg_score <- ifelse(grepl(pattern="p\\.?h\\.?d\\.?", degs$degree) & sapply(degs$deg_score, function(x) x==0), 10, degs$deg_score)
  degs$deg_score <- ifelse(grepl(pattern="j\\.?d\\.?|jur.*doc", degs$degree) & sapply(degs$deg_score, function(x) x==0), 9, degs$deg_score)
  degs$deg_score <- ifelse(grepl(pattern=".*post.*grad", degs$degree) & sapply(degs$deg_score, function(x) x==0), 8, degs$deg_score)
  degs$deg_score <- ifelse(grepl(pattern="mast.*|^grad", degs$degree) & sapply(degs$deg_score, function(x) x==0), 6, degs$deg_score)
  degs$deg_score <- ifelse(grepl(pattern="m\\.?sc?\\.?", degs$degree) & sapply(degs$deg_score, function(x) x==0), 6, degs$deg_score)  
  degs$deg_score <- ifelse(grepl(pattern="^m\\.?a\\.?|^b.*eng", degs$degree) & sapply(degs$deg_score, function(x) x==0), 5, degs$deg_score) 
  degs$deg_score <- ifelse(grepl(pattern="b\\.?sc?\\.?", degs$degree) & sapply(degs$deg_score, function(x) x==0), 4.5, degs$deg_score) 
#   degs$deg_score <- ifelse(grep(pattern="b\\.?a\\.?", degs$degree) & sapply(degs$deg_score, function(x) x==0), 4.0, degs$deg_score) 
  return(degs)
}

#'
#' Weight score by factor based on title
#' @param results dataframe must have "score" and "title" columns
#' @return data.frame with scores adjusted
#'
weightScoreByTitle <- function(results) {
  library(stringr)
  results$score <- sapply(results[,"total_money_raised"], function(x) str_extract(x,"[0-9.]+"))
  exchange <- c("$"=1.0, "¥"=.01, "£"=1.5, "€"=1.3, "c$"=0.95)
  unit <- c("m"=1e6, "k"=1e3, "b"=1e9)
  results[,"score"] <- as.numeric(results[,"score"]) * unit[str_extract(results[,"total_money_raised"], "([^0-9.]+)$")]
  results[,"score"] <- results[,"score"] * sapply(results[,"title"], weightByTitle)
  return(results)
}

#'
#' Generate a random sample of specified size
#'
writeSampleCSV <- function(file="data/sample.csv", dataSize=5000, sampleSize=100) {
  r <- scoreCrunchBase(dataSize)
  write.table(r[sample(x=1:dataSize,size=sampleSize),], file=file, append=F, row.names=F, sep=",")
}

#' Filter out investors
#' @description Filter out all rows from data frame with matching name to an investor
filterInvestor <- function(x) {
  # TODO(anthony): queryCypher2 has a bug for returning single column
  ivs <- queryCypher2("match (p:PersonGUID)-[:HAS_EMPLOYMENT]->(f) where f.firm_type_of_entity! = \"financial_org\" return distinct p.source_uid, p.twitter_username?")
  names(ivs) <- c("person", "twitter")
  filtered <- x[!x$person %in% as.vector(ivs$person),]
  return(filtered)
}

#' Filter out laywers from input data frame
filterLawyer <- function(x) {
  counsels <- queryCypher2("match (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j) where j.title! =~ \".*[Cc]ounsel.*\" return p.source_uid, j.title")
  names(counsels) <- c("person", "title")
  filtered <- x[!x$person %in% as.vector(counsels$person),]
  return(filtered)
}

topSchoolsByVcs <- function() {
  aggregateBySchoolNames(query="match (i:Institution)-[:ATTENDED]-(e)-[:HAS_EDUCATION]-(p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment) where  j.firm_type_of_entity! = \"financial_org\" and i.value! <> \"\" WITH i.value! as school, count(distinct p) as students return school, students;")  
}

topSchoolsByFounders <- function() {
  aggregateBySchoolNames(query="match (i:Institution)-[:ATTENDED]-(e)-[:HAS_EDUCATION]-(p:PersonGUID)-[:HAS_EMPLOYMENT]->(j:Employment) where j.title! =~ \".*founder.*\" and i.value! <> \"\" WITH i.value! as school, count(distinct p) as students return school, students;")
}

aggregateBySchoolNames <- function(students=NA, query) {
  if (is.na(students)) {
    students <- queryCypher2(query)
  }
  print(paste("Found", nrow(students), "schools and total of", sum(as.numeric(students$X2)), "students"))
  df <- data.frame(school=c("mit","harvard","stanford","university of pennylvania", "columbia university","uc berkeley",
                            "princeton", "university of chicago", "northwestern university", "cambridge", "dartmouth", "yale", "duke"),
                   count=c(
                     sum(as.numeric(students[grepl("massachu.*inst|mit",students$X1) & !grepl("rmit|smith|amity", students$X1),]$X2)),
                     sum(as.numeric(students[grepl("harvard",students$X1),]$X2)),
                     sum(as.numeric(students[grepl("stanford",students$X1),]$X2)),
                     sum(as.numeric(students[grepl("penn",students$X1) & !grepl("indianna|state|york|manor", students$X1),]$X2)),
                     sum(as.numeric(students[grepl("colum",students$X1) & !grepl("british|princeton|carolina|mailman|college", students$X1),]$X2)),
                     sum(as.numeric(students[grep("berk",students$X1),]$X2)),
                     sum(as.numeric(students[grep("princeton",students$X1),]$X2)),
                     sum(as.numeric(students[grepl("chicago",students$X1) & !grepl("loyola|illinois|columbia|professional|argosy|art institute", students$X1),]$X2)),
                     sum(as.numeric(students[grepl("northwestern",students$X1) & !grepl("military", students$X1),]$X2)),
                     sum(as.numeric(students[grepl("cambridge",students$X1) & !grepl("charlton", students$X1),]$X2)),
                     sum(as.numeric(students[grepl("dartmouth",students$X1),]$X2)),
                     sum(as.numeric(students[grepl("yale",students$X1),]$X2)),
                     sum(as.numeric(students[grepl("duke",students$X1) & !grepl("manor", students$X1),]$X2))))
  print(paste("Matched", nrow(df), "schools", "with", sum(df$count), "students"))
  df <- df[order(df$count, decreasing=T),]
  return(df)
}

#'
#' Aggregate student count by school names 
#' @description Aggregate student count by school using "parallel" package.  
#'
aggregateBySchoolNames2 <- function(students=NA, query) {
  library(parallel)
  if (is.na(students)) {
    students <- queryCypher2(query)
  }
  print(paste("Found", nrow(students), "schools and total of", sum(as.numeric(students$X2)), "students"))
  df <- null
  df <- rbind(df, c("mit", "massachu.*inst|mit", "rmit|smith|amity"))
  df <- rbind(df, c("harvard", "harvard", NULL))
  df <- data.frame(df)
  names(df) <- c("school", "pos", "neg")
}

topConnectedVCs <- function(top=n) {
  
  # first query to pull all VCs connected because they worked/work for same investment company
  vc <- queryCypher2("match (p:PersonGUID)-[:HAS_EMPLOYMENT]->(j)-[:HAS_EMPLOYMENT_FIRM]->(f:EmploymentFirm)<-[:HAS_EMPLOYMENT_FIRM]-(k)<-[:HAS_EMPLOYMENT]-(q:PersonGUID) where j.firm_type_of_entity! = \"financial_org\" return p.source_uid, f.value, q.source_uid")
  names(vc) <- c("person", "firm", "coworker")
  vc <- subset(vc, as.character(person)!=as.character(coworker)) # doesn't work with as.charactor because # of factor levels have to be the same
  vc$person <- unlist(vc$person)
  vc$coworker <- unlist(vc$coworker)
  vc <- cbind(vc, score=rep(5,nrow(vc)))
  
  # second query 
  ir <- queryCypher2("match (m:EmploymentFirm)<-[:HAS_EMPLOYMENT_FIRM]-j<-[:HAS_EMPLOYMENT]-(a:PersonGUID), m<-[:HAS_EMPLOYMENT_FIRM]-l<-[:HAS_EMPLOYMENT]-(b:PersonGUID),  m-[:HAS_FUNDING]-mm-[:HAS_INVESTOR]-i-[:HAS_EMPLOYMENT_FIRM]-k-[:HAS_EMPLOYMENT]-a, m-[:HAS_FUNDING]-mmm-[:HAS_INVESTOR]-ii-[:HAS_EMPLOYMENT_FIRM]-kk-[:HAS_EMPLOYMENT]-b return distinct a.source_uid!, m.value!, b.source_uid!")
  names(ir) <- c("person", "firm", "coworker")
  # last row is NA/NA, work around
  ir <- ir[-nrow(ir), ]
  ir$person <- unlist(ir$person)
  ir$coworker <- unlist(ir$coworker)
  ir <- cbind(ir, score=rep(100,nrow(ir)))
  
#   relations <- rbind(vc, ir)
  g <- graph.edgelist(as.matrix(ir[,c("person", "coworker")]))
  E(g)$weight <- ir[,"score"]
  pr <- sort(page.rank.old(g), decreasing=T)
  return(pr)
  
#   pr <- page.rank(g)$vector
#   return(head(sort(pr, decreasing=T)))
}

sanityTest <- function() {
  relations <- queryCypher2("match x-[r]->y return head(labels(x)) as head, type(r), head(labels(y)) as tail, count(*) order by count(*) desc; ")
}

cloudMapFromSkillsets <- function() {
  library("tm")
  library("RWeka")
  library("wordcloud")
  skills <- queryCypher2("match s:Skill return s.display_name!")
  corpus <- tm_map(x=Corpus(DataframeSource(tail(skills,-1))), FUN=removeWords, stopwords("english"))
  tdm <- TermDocumentMatrix(corpus)
  wordFreq <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)
#   grayLevels <- gray( (wordFreq+10) / (max(wordFreq)+10) )
#   wordcloud(words=names(wordFreq), freq=wordFreq, min.freq=3, random.order=F, colors=grayLevels)
  wordcloud(words=names(wordFreq), freq=wordFreq, min.freq=3, random.order=F, colors=brewer.pal(8, "Dark2"))
}






