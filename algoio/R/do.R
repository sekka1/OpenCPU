#' Gets user input
#' @param question prompt or question to display to user
#' @param defvalue value to return if user hit enter 
getinput <- function(question, defvalue=NULL) {
    input = NULL;
    while (TRUE) {
    	input = readline(paste(question, "[", defvalue, "] :"))
    	input
        if (nchar(input) == 0 && !is.null(defvalue)) {
            return(defvalue)
        }
        else if (nchar(input) == 0) {
            cat("Cannot be empty")
        }
        else {
            return(input)
        }
    }
}

# Parse DESCRIPTION into convenient format
read.description <- function(file) {
  dcf <- read.dcf(file)  
  dcf_list <- setNames(as.list(dcf[1, ]), colnames(dcf))
  lapply(dcf_list, str_trim)
}

#' Publish entire R package to Algorithms.io platform
#' @param package.dir the package's top directory
#' @return response from Algorithms.io platform including endpoint of the new package
#' @author anthony@@algorithms.io
#' @keywords upload, publish
#' @export
algoio.publish <- function(package.dir) {
  swagger <- generate_swagger(package.dir)
  # Create an json file prefixed with the package name
  jsonfile <- paste0(swagger$package$Package, 'swagger.json')
  sink(jsonfile)
  cat(toJSON(swagger))
  sink()
  
  system(paste('R CMD build ', normalizePath(package.dir)))
  # where is the package tarball
  tarball <- list.files(pattern=paste0(swagger$package$Package,'.*gz'))
  
  if (!exists('authToken')) 
    authToken <- getinput("Authentication Token")
  if (!exists('algoServer'))
    algoServer <- getinput('Algorithms.io Server', defvalue='https://v1.api.algorithms.io/')
  
  content <- executeAPICall(authToken, algoServer, 
                            'packages', action=postForm, 
                            definition=toJSON(swagger), package=fileUpload(tarball))
  algoid = fromJSON(content) 
  print(paste("Successfully uploaded package", basename(package.dir), ", reference is", algoid))
  cat(fromJSON(sub(".*(\\{\"apiVersion.*)", "\\1", content)))
}

algoio.show <- function(package.id) {
  if (!exists('authToken')) 
    authToken <- getinput("Authentication Token")
  if (!exists('algoServer'))
    algoServer <- getinput('Algorithms.io Server', defvalue='https://v1.api.algorithms.io/')
  content <- executeAPICall(
    authToken, 
    "http://pod3.staging.www.algorithms.io/", 
    paste0('catalog/swagger/id/',package.id))
  return(sub(".*(\\{\"apiVersion.*)", "\\1", content))
}

algoio.run <- function(algo.id) {
  if (!exists('authToken')) 
    authToken <- getinput("Authentication Token")
  if (!exists('algoServer'))
    algoServer <- getinput('Algorithms.io Server', defvalue='https://v1.api.algorithms.io/')
  content <- executeAPICall(
    authToken, 
    algoServer, 
    paste0('jobs/swagger/id/', algo.id),
    action=postForm)
  return(sub(".*(\\{\"apiVersion.*)", "\\1", content))
}

#' Upload R data.frame to algorithms.io 
#' @description Upload data.frame to algorithms.io
#' @param x @@type=data.frame
#' @keywords dataframe
#' @export 
algoio.upload.dataframe <- function(x) {
  stopifnot(is.data.frame(x))
  require("RJSONIO")
  
  if (!exists('authToken')) 
    authToken <- getinput("Authentication Token")
  if (!exists('algoServer'))
    algoServer <- getinput('Algorithms.io Server', defvalue='https://v1.api.algorithms.io/')
  
  # 
  dir.create(path='~/.algoio', showWarnings=FALSE, recursive=TRUE)
  file.create('~/.algoio/dataset')
  write.table(x, '~/.algoio/dataset')

  content <- executeAPICall(authToken, algoServer, 'dataset', action=postForm, theFile=fileUpload('~/.algoio/dataset'))
  json <- fromJSON(content)[[1]]
  if (json$api[['Authentication']] == 'Success')
    print(paste('Uploaded data frame with returned reference', json$data))
}

algoio.delete.dataset <- function(id) {
  require(stringr)
  if (!exists('authToken')) 
    authToken <- getinput("Authentication Token")
  if (!exists('algoServer'))
    algoServer <- getinput('Algorithms.io Server', defvalue='https://v1.api.algorithms.io/')
  content <- executeAPICall(authToken, algoServer, "/dataset");
  dataset <- fromJSON(str_extract(content, "\\{.*\\}"))$data
  if (id %in% sapply(dataset,'[[','id'))
    response <- executeAPICall(authToken, algoServer, paste0('dataset/',id), action=httpDELETE)
  return(response)
}

makeCache <- function() {
  cache <- new.env(parent=emptyenv())
  list(get = function(key) cache[[key]],
       set = function(key, value) cache[[key]] <- value,
       ## next two added in response to @sunpyg
       load = function(rdaFile) load(rdaFile, cache),
       ls = function() ls(cache))
}

#' Get package level data from DESCRIPTION file
get_package_data <- function(package.dir) {
  require('stringr')
  # If description present, use Collate to order the files
  # (but still include them all, and silently remove missing)
  DESCRIPTION <- file.path(package.dir, "DESCRIPTION")
  if (file.exists(DESCRIPTION)) {
    desc <- read.description(DESCRIPTION)
    # fields that need splitting    
    tosplit <- c('Author', 'Description', 'Depends', 'Collate', 'Imports')
    desc[tosplit] <- lapply(desc[tosplit], function(x) {if (!is.null(x)) { x <- strsplit(x, split=',\n') }})
    return(desc)
  }
  else {
    package = list(name=getinput("Please enter name of package:"),
   	version = getinput("What is the version?"),
    	author = getinput(question="Author: ",defvalue=Sys.info()["user"]),
    	description = getinput(question="Description"),
    	contributors = getinput(question="Contributors separated by commas"),
    	tags = getinput(question="Tags"))
    cat(toJSON(package))
  }
}

#' Generates a swagger document from a package directory
#' @param package.dir the package's top directory
generate_swagger <- function(package.dir) {
    require("roxygen2")
    require("RJSONIO")

    swagger <- fromJSON(getURL('https://s3.amazonaws.com/r-package/algoio.swagger.json'))
    # swagger <- fromJSON('doc/swagger.json')
    r_files <- dir(file.path(package.dir, "R"), "[.Rr]$", full.names = TRUE)
    parsed <- parse.files(r_files)
    first <- TRUE
    for (j in 1:length(parsed)) {
#       print(paste('j=',j))
      if (is.null(parsed[[j]]$export)) next
      x = parsed[[j]]
#       print(paste('x =', x))
      if (!first)
        swagger$apis[[length(swagger$apis) + 1]] <- swagger$apis[[1]]
      else
        first <- FALSE
      swagger$apis[[length(swagger$apis)]]$operations[[1]]$summary <- x$introduction
      swagger$apis[[length(swagger$apis)]]$operations[[1]]$nickname <- x$assignee
      k = 2;
      for (i in 1:length(x)) { 
        if (names(x)[i] == 'param') {
          k <- k + 1;
          swagger$apis[[length(swagger$apis)]]$operations[[1]]$parameters[[k]] <- 
            c(allowMultiple='true', dataType='string', 
              description=x[i]$param$description,
              name=x[i]$param$name, 
              paramType='query', required='true')
        }
      }
    }
    
    swagger$package <- get_package_data(package.dir)
    
    return(swagger)
}

#' Calls a URL on the API site with the given relative path and action
executeAPICall <- function(authToken, algoServer="https://v1.api.algorithms.io/", relativePath, action=getURL, ...) {
  require(RCurl)
  CAINFO = paste(system.file(package="RCurl"), "/CurlSSL/ca-bundle.crt", sep = "")
  
  url <- paste(algoServer,relativePath,sep="");
  theheader <- c('authToken' = authToken);
  #note the cookie might cause some trouble with apparmor
  cookie <- 'cookiefile.txt'
  curlH <- getCurlHandle(
    cookiefile = cookie,
    useragent =  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en - US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
    header = TRUE,
    verbose = FALSE,
    netrc = TRUE,
    maxredirs = as.integer(20),
    followlocation = TRUE,
    ssl.verifypeer = FALSE,
    httpheader = theheader
  );
  return(action(url, curl = curlH, cainfo = CAINFO, ...));
}
