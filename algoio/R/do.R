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
  system(paste('R CMD build ', normalizePath(package.dir)))
  # where is the package tarball
  tarball <- list.files(pattern=paste(basename(package.dir),'.*gz'))
}

#' Upload R data.frame to algorithms.io 
#' @description
#' @param x @@type=data.frame
algoio.upload.dataframe <- function(x) {
  stopifnot(is.data.frame(x))
  
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

algoio.get.dataframe

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
  library('stringr')
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
    library("roxygen2")
    library("RJSONIO")

    swagger <- fromJSON('doc/swagger.json')
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

#'  
algoio.upload <- function() {
  
}

#' Sample function used for testing publish
#' @param param1 string parameter
#' @param param2 string parameter with null default
#' @param param3 numeric parameter
#' @author anonymous@@algorithms.io
#' @export
#' @keywords foo, bar
algoio.foobar <- function(param1="default string value", param2=NULL, param3=123) {
    list()
}