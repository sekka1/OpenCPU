\name{queryCypher2}
\alias{queryCypher2}
\title{Executes cypher query}
\usage{
  queryCypher2(querystring,
    serverURL = "http://166.78.27.160:7474/db/data/cypher")
}
\arguments{
  \item{serverURL}{URL of Neo4j cypher query endpoint.  It
  should end with db/data/cypher}

  \item{querystring}{Query}
}
\description{
  Executes cypher query to Neo4j server instance
}
\examples{
queryCypher2("match (e)-[:HAS_EMPLOYMENT]->(j) return e,j limit 10")
}

