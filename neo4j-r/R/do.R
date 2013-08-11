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
  
  data <- data.frame(t(sapply(result$data, function(x) sapply(x, function(y) if (length(y)>1) y<-paste(y, collapse=',') else y))))
  
  # data <- data.frame(t(sapply(result$data, unlist)))
  
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
                "WHERE f.total_money_raised! <> \"$0\" AND HAS(j.title) AND HAS(e.type)",
                "RETURN p.source_uid, f.value, j.title, e.institution, e.type, c.source_uid, f.total_money_raised",
                (if (count<0) "" else paste("LIMIT",as.integer(count))));
  
  results <- queryCypher2(query);
  names(results) <- c("person", "company", "title", "school", "degree", "coworker", "total_money_raised")
  
  results$score <- sapply(results[,"total_money_raised"], function(x) str_extract(x,"[0-9.]+"))
  
  # Add a numeric feature to the school
  results <- scoreSchool(results)

  # Add a numeric feature based on degree description
  results <- scoreDegree(results)
  
  exchange <- c("$"=1.0, "¥"=.01, "£"=1.5, "€"=1.3, "c$"=0.95)
  unit <- c("m"=1e6, "k"=1e3, "b"=1e9)
  results[,"score"] <- as.numeric(results[,"score"]) * unit[str_extract(results[,"total_money_raised"], "([^0-9.]+)$")]
  results[,"score"] <- results[,"score"] * sapply(results[,"title"], weightByTitle)
  results
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

crunchBaseBasicStats <- function(serverURL="http://166.78.27.160:7474/db/data/cypher") {
  queryCypher2("match (p:PersonGUID) return count(p);")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) return count(p);")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) AND HAS(d.graduated_year) return count(p) ;")
  queryCypher2("match (p:PersonGUID)-[:HAS_EDUCATION]->(d) where HAS(d.institution) AND HAS(d.graduated_year) AND HAS(d.type) return count(p);")
  queryCypher2("match (d:Degree) return count(d)")  
  # number of institutions
  queryCypher2("match (i:Institution) return length(collect(i.value?))")
}

#' 
#' Add a numeric value feature to the data frame
#' @description Adds a new column based on the names of school
#' @param edu input dataset with a column named "school"
#' @return dataset with added column called "school_score"
#' @export
#'
scoreSchool <- function(edu, scores=NULL) {
  if (any(is.null(edu)) || any(is.na(edu))) {
    warning('x cannot have any NA')
    return
  }
  if (is.null(scores)) {
    scores <- read.csv("~/git/opencpu/neo4j-r/data/University Rankings 2011 QS.csv")
    scores <- scores[,c("School.Name", "Score")]
  } 
  # try partial match by grep first 
  edu$school_score <- sapply(edu$school, function(x) ave(scores[grep(str_trim(x),scores$School.Name,ignore.case=T),]$Score)[1])
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
#' Generate a random sample of specified size
#'
writeSampleCSV <- function(file="~/git/opencpu/neo4j-r/data/sample.csv", dataSize=5000, sampleSize=100) {
  r <- scoreCrunchBase(dataSize)
  write.table(r[sample(x=1:dataSize,size=sampleSize),], file=file, append=F, row.names=F, sep=",")
}

