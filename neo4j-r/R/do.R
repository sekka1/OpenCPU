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

#' 
#'
#'
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
    .05;
  }
  else if (grepl("chairman",title)) {
    .15;
  }
  else if (grepl("board member",title) || grepl("board+member",title)) {
    .1;
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

#' Creates data frame with these columns
#'
#'
#'
scoreAllPersons <- function() {
  persons <- queryCypher2(querystring="match (e)-[:HAS_EMPLOYMENT]->(j)-[:HAS_EMPLOYMENT_FIRM]->(f),(j)-[:HAS_EMPLOYMENT_TITLE]->(t),(f)<-[:HAS_EMPLOYMENT_FIRM]-k<-[:HAS_EMPLOYMENT]-(p) where HAS(f.total_money_raised) and f.total_money_raised <> \"$0\" return e.source_uid, f.value, t.value, count(distinct p), f.total_money_raised order by e.source_uid;")
  names(persons) <- c("person", "company", "title", "employees_on_base_crunchbase", "total_money_raised")
  persons$score <- sapply(persons[,"total_money_raised"], function(x) str_extract(x,"[0-9.]+"))
  exchange <- c("$"=1.0, "¥"=.01, "£"=1.5, "€"=1.3, "c$"=0.95)
  unit <- c("m"=1e6, "k"=1e3, "b"=1e9)
  persons[,"score"] <- as.numeric(persons[,"score"]) * unit[str_extract(persons[,"total_money_raised"], "([^0-9.]+)$")]
  persons[,"score"] <- persons[,"score"] * sapply(persons[,"title"], weightByTitle)
  persons
}

