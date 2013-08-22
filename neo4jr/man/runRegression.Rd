\name{runRegression}
\alias{runRegression}
\title{Run regression on all persons from CrunchBase}
\usage{
  runRegression(count = 1000)
}
\description{
  First query produce all coworker relations, then used to
  generate pagerank scores Second query creates personal
  attributes, such as education and work titles, used to
  compute numeric variables. Then pagerank scores are added
  as feature
}

