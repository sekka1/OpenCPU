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
#' @import RCurl, RJSONIO, bitops
#' @include RCurl, RJSONIO, bitops
#' @examples queryCypher2("match (e)-[:HAS_EMPLOYMENT]->(j) return e,j limit 10")
#'
queryCypher2 <- function(serverURL="http://166.78.24.138:7474/db/data/cypher", 
                         querystring) {
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
  
  data <- data.frame(t(sapply(result$data, unlist)))
  #names(data) <- result.json$columns
  junk <- c("outgoing_relationships","traverse", "all_typed_relationships","property","self","properties","outgoing_typed_relationships","incoming_relationships","create_relationship","paged_traverse","all_relationships","incoming_typed_relationships")
  data <- data[,!(names(data) %in% junk)] 
  data
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

#' Score persons  
#' @description Score is based on the total money raised of a company, discounted according to person's job title.  
#' @return a data.frame with columns "person", "coworker" and "score"
#'
scoreCrunchBase <- function() {
  library(stringr)
  persons <- queryCypher2(querystring="match (e)-[:HAS_EMPLOYMENT]->(j)-[:HAS_EMPLOYMENT_FIRM]->(f),(j)-[:HAS_EMPLOYMENT_TITLE]->(t),(f)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(p) where HAS(f.total_money_raised) and f.total_money_raised <> \"$0\" return e.source_uid, f.value, t.value, p.source_uid, f.total_money_raised limit 10000;")
  names(persons) <- c("person", "company", "title", "coworker", "total_money_raised")
  persons$score <- sapply(persons[,"total_money_raised"], function(x) str_extract(x,"[0-9.]+"))
  exchange <- c("$"=1.0, "¥"=.01, "£"=1.5, "€"=1.3, "c$"=0.95)
  unit <- c("m"=1e6, "k"=1e3, "b"=1e9)
  persons[,"score"] <- as.numeric(persons[,"score"]) * unit[str_extract(persons[,"total_money_raised"], "([^0-9.]+)$")]
  persons[,"score"] <- persons[,"score"] * sapply(persons[,"title"], weightByTitle)
  persons
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
  E(g)$weight <- relations[,"score"]
  
  plot.igraph(g)
  g
}

#'
#' #' Run page rank on igraph from CrunchBase
#' @description Run igraph page rank algorithm on graph with scores from Crunchbase data, show the top entries with scores
#' @export
#' 
runPageRank <- function(top=20) {
  graph <- createGraph(scoreCrunchBase())
  vector <- page.rank(graph)$vector
  head(sort(vector, decreasing=T),n=top)
  vector
}





