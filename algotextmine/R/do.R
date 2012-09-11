#this maps a directory
listFiles <- function( folder = "documents" )
{
	path <- paste(config_dataFolder,folder,sep="/");
	return(list.files(path = path))
}

fetchDocument <- function( filename )
{
	require(tm);
	
	#path <- paste(config_dataFolder,folder,sep="/")
	#setwd(path);


	con  <- file(filename, open = "r")
	stringText <- "";
	while (length(oneLine <- readLines(con, n = 1, warn = FALSE)) > 0) {
	  stringText <- paste(stringText,gsub("<(.|\n)*?>","",oneLine));
	} 

	close(con)

	print(stringText);
	#if (exists("myDocument")) rm(myDocument)
	#if (exists("text.corp")) rm(text.corp)
	myDocument <- c(stringText)
	text.corp <- Corpus(VectorSource(myDocument))
	#########################
	text.corp <- tm_map(text.corp, stripWhitespace)
	text.corp <- tm_map(text.corp, removeNumbers)
	text.corp <- tm_map(text.corp, removePunctuation)
	## text.corp <- tm_map(text.corp, stemDocument)
	text.corp <<- tm_map(text.corp, removeWords, c("the", stopwords("english")))
	print("fetchDocument : Loaded Text - ");

	return(DocumentTermMatrix(text.corp))	
}

#' Input a dictionary to score the document with
loadDictionary <- function( dtm, dictionary)
{
	
	#path <- paste(config_dataFolder,"dictionary",sep="/")
	#setwd(path);
	
	con  <- file(dictionary, open = "r")
	stringText <- "";
	while (length(oneLine <- readLines(con, n = 1, warn = FALSE)) > 0) {
	  stringText <- paste(stringText,oneLine);
	} 

	close(con)

	stringTextTokens <- unlist(strsplit(stringText,split=","));
	stringTextTokens <<- gsub("^ ", "", stringTextTokens)
}
#' if we normalize the score then we do TAGS_FOUND / TOTAL_NON_SPARSE_WORDS
calculateScore <- function(dtm)
{
	score <- tm_tag_score( text.corp[[1]], stringTextTokens);	
	return(score);
}

#' Computes scores of documents by text frequency analysis
#' 
#' @param files A list of files you want to have scored by the system
#' @param type list files
#' @param dictionaries A list of dictionary file names complete with extensions like c("beachDictionary.txt","golfDictionary.txt")
#' @param type list dictionaries
#' @return Scored documents based off of dictionaries
#' @author Robert I.
#' @export
mainAnalyze <- function( files, dictionaries )
{
	config_dataFolder <<- "/opt/Data-Sets/Automation";
	require(RJSONIO);
	require(tm);
	myParentList <- list();
	dataHere <<- "";
	tempStr <<- "";
	for (myfile in files)
	{
		#fetch 1 document and tokenize it
		dtm <- fetchDocument(myfile);

		#then we will load it here
		for (dictionary in dictionaries)
		{
			loadDictionary(dtm,dictionary);
			dtm.mat <- as.matrix(dtm)
			dtm.mat 	
			total_words_unique <- length(dtm.mat)

			myList <<- list()
			myList[["fileName"]] <- myfile
			myList[["dictionary"]] <- dictionary
			score <- calculateScore(dtm);
			myList[["rawScore"]] <- score
			myList[["normalScore"]] <- score/total_words_unique;
			#myParentList[length(myParentList)+1] <- myList
			tempStr <<- paste(tempStr,toJSON(myList));
		}

		rm(dtm)
	}
	dataHere <<- tempStr;
}

