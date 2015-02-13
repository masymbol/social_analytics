library(rmongodb)
library(plyr)
library(grid)
library(lattice)
library(survival)
library(splines)
library(Formula)
library(Hmisc)
library(jsonlite)

 args <-commandArgs(TRUE)
 ans <- as.character(args[1])
 
logistic <- function(ans)
{
m = mongo.create(host = "localhost")
mongo.is.connected(m)
mongo.get.databases(m)
db <- ans

collection <- ans
namespace <- paste(db, collection, sep=".") 
print("namespace---")
print(namespace)

query = mongo.bson.buffer.create()
# when complete, make object from buffer
query = mongo.bson.from.buffer(query)

# define the fields
fields = mongo.bson.buffer.create()
mongo.bson.buffer.append(fields, "created_at", 1L)
mongo.bson.buffer.append(fields, "text", 1L)
mongo.bson.buffer.append(fields, "id_str", 1L)
mongo.bson.buffer.append(fields, "user.id", 1L)
mongo.bson.buffer.append(fields, "user.profile_image_url_https", 1L)
mongo.bson.buffer.append(fields, "user.profile_image_url", 1L)
mongo.bson.buffer.append(fields, "user.name", 1L)
mongo.bson.buffer.append(fields, "user.screen_name", 1L)

# when complete, make object from buffer
fields = mongo.bson.from.buffer(fields)

# create the cursor
cursor = mongo.find(m, ns = namespace, query = query, fields = fields)

gids = data.frame(stringsAsFactors = FALSE)
while (mongo.cursor.next(cursor)) {
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  # make it a dataframe
  tmp.df = as.data.frame(t(unlist(tmp)), stringsAsFactors = F)
  # bind to the master dataframe
  gids = rbind.fill(gids, tmp.df)
}
#write.csv(gids,"logicpp.csv")
#No need to do dis above cbind but keeping code as it is. gids is allready a data frame with above columns
raw_data <- cbind(gids$text,gids$created_at,gids$id_str,gids$user.id,gids$user.profile_image_url_https,gids$user.profile_image_url,gids$user.name,gids$user.screen_name)
raw_data_df <- data.frame(raw_data)
raw_data_df$X2 <- gsub(first.word(raw_data_df$X2),"",raw_data_df$X2)

# Remove trailing space
trim.leading <- function (x)  sub("^\\s+", "", x)
raw_data_df$X2 <- trim.leading(raw_data_df$X2)
write.csv(raw_data_df,"dhoni_after.csv")

raw_data_df$X2 <- sub("Jan","01",raw_data_df$X2)
raw_data_df$X2 <- sub("Feb","02",raw_data_df$X2)
raw_data_df$X2 <- sub("Mar","03",raw_data_df$X2)
raw_data_df$X2 <- sub("Apr","04",raw_data_df$X2)
raw_data_df$X2 <- sub("May","05",raw_data_df$X2)
raw_data_df$X2 <- sub("Jun","06",raw_data_df$X2)
raw_data_df$X2 <- sub("Jul","07",raw_data_df$X2)
raw_data_df$X2 <- sub("Aug","08",raw_data_df$X2)
raw_data_df$X2 <- sub("Sep","09",raw_data_df$X2)
raw_data_df$X2 <- sub("Oct","10",raw_data_df$X2)
raw_data_df$X2 <- sub("Nov","11",raw_data_df$X2)
raw_data_df$X2 <- sub("Dec","12",raw_data_df$X2)
#write.csv(raw_data_df,"logic__ppss.csv")

#format date column
raw_data_df$X2 <- strftime(as.POSIXct(raw_data_df$X2,format="%m %d %H:%M:%S +0000 %Y"),"%m/%d/%Y %H:%M:%S")
raw_data_df$X2 <- as.POSIXct(raw_data_df$X2,format="%m/%d/%Y %H:%M:%S") #change Date col class to POSIXct

raw_data_df$X2[1] < raw_data_df$X2[6] #compare Dates
colnames(raw_data_df)<-c("Text","Dates","id_str","user.id","user.profile_image_url_https","user.profile_image_url","user.name","user.screen_name")

#write.csv(raw_data_df,"DateText.csv")

last_date <- tail(raw_data_df$Dates,n=1)

#IMP Details
#library(lubridate)
#dd <- ymd_hms(raw_data_df$X2)
#View(dd)
#hour(raw_data_df$X2[1])

# Analysis

pos = scan('/home/purva/Desktop/project/positive-words.txt', what='character', comment.char=';')
neg = scan('/home/purva/Desktop/project/negative-words.txt', what='character', comment.char=';')
t <- raw_data_df$Text

score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  library(plyr)
  
  library(stringr)
  scores = laply(sentences, function(sentence, pos.words, neg.words) 
  {
    sentence = gsub('[[:punct:]]', '', sentence)
    
    sentence = gsub('[[:cntrl:]]', '', sentence)
    
    sentence = gsub('\\d+', '', sentence)
    
    word.list = str_split(sentence, '\\s+')
    
    words = unlist(word.list)
    
    pos.matches = match(words, pos.words)
    
    neg.matches = match(words, neg.words)
    pos.matches = !is.na(pos.matches)
    
    neg.matches = !is.na(neg.matches)
    score = sum(pos.matches) - sum(neg.matches)
    
    return(score)
    
  }, pos.words, neg.words, .progress=.progress )
   scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}

 analysis = score.sentiment(t, pos, neg) 
 
 ### Twitter Review ####
 nuetral <- analysis[which(analysis$score==0),]
 positive <- analysis[which(analysis$score>0),]
 negative <- analysis[which(analysis$score<0),]
  
 nuet_l <-data.frame(length(nuetral$score))
 nuet_l["class"] <- "nuetral"
 pos_l <-data.frame(length(positive$score))
 pos_l["class"] <- "positive"
 neg_l <-data.frame(length(negative$score))
 neg_l["class"] <- "negative"
 colnames(nuet_l)[1] <- "length"
 colnames(pos_l)[1] <- "length"
 colnames(neg_l)[1] <- "length"
 sentiment_file <- rbind(nuet_l,pos_l,neg_l)
 
  # connecting R to mongoDB
  mongo.get.database.collections(m, db)
  #collection <- "Twitt1"
  collection <- paste(ans,"_sentiment_file", sep="")
  namespace <- paste(db, collection, sep=".") 
  tw_json <- toJSON(sentiment_file)
  tw_bson <- mongo.bson.from.JSON(tw_json)
  tw_data <- mongo.insert(m, namespace, tw_bson)
  print("Erroor1")
  
  #collection1 <- "Twitter_nuetral1"
  collection1 <- paste(ans,"_Twitter_Nuetral", sep="")
  dt <- sapply(nuetral$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
  nuetral$text <- dt  #replace text column by dt
  namespace1 <- paste(db, collection1, sep=".") 
  tw_json1 <- toJSON(nuetral)
  tw_bson1 <- mongo.bson.from.JSON(tw_json1)
  tw_data1 <- mongo.insert(m, namespace1, tw_bson1)
  print("Erroor2")
  
  collection2 <- paste(ans,"_Twitter_Pos", sep="")
  dt <- sapply(positive$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
  positive$text <- dt  #replace text column by dt
  namespace2 <- paste(db, collection2, sep=".") 
  tw_json <- toJSON(positive)
  tw_bson <- mongo.bson.from.JSON(tw_json)
  tw_data <- mongo.insert(m, namespace2, tw_bson)
  print("Erroor3")

  collection3 <- paste(ans,"_Twitter_Neg", sep="")
  dt <- sapply(negative$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
  negative$text <- dt  #replace text column by dt
  namespace3 <- paste(db, collection3, sep=".") 
  tw_json <- toJSON(negative)
  tw_bson <- mongo.bson.from.JSON(tw_json)
  tw_data <- mongo.insert(m, namespace3, tw_bson)
  print("Erroor4")

  txt <-data.frame(analysis$text)
  scr <-data.frame(analysis$score)
  res <- cbind(scr,txt) 
  colnames(res) <- c("analysis_score","analysis_text")

  collection4 <- paste(ans,"_Twitter_score_analysis", sep="")
  dt <- sapply(res$analysis_text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
  res$analysis_text <- dt  #replace text column by dt
  namespace4 <- paste(db, collection4, sep=".") 
  tw_json <- toJSON(res)
  tw_bson <- mongo.bson.from.JSON(tw_json)
  tw_data <- mongo.insert(m, namespace4, tw_bson)
  print("Erroor5")

  ###### sentiment over Time ########
 d <-raw_data_df$Dates
 sent_over_time <- cbind(analysis,d)
 collection5 <- paste(ans,"_Sentiment_over_time", sep="")
 dt <- sapply(sent_over_time$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
 sent_over_time$text <- dt  #replace text column by dt
 namespace5 <- paste(db, collection5, sep=".") 
 tw_json <- toJSON(sent_over_time)
 tw_bson <- mongo.bson.from.JSON(tw_json)
 tw_data <- mongo.insert(m, namespace5, tw_bson)
 print("Erroor6")
 #write.csv(sent_over_time,"sentiment_graphs/Twitter_sentiment_over_time.csv")

############################## most +ve and _ve tweets ############################
 a <- grep(3, analysis$score) #find 3 of score
 print("most +ve tweet :-")
 p<-max(analysis$score,na.rm=TRUE) # find max
 print("most +ve tweet1 :-")
 q<-min(analysis$score,na.rm=TRUE)
 print("most +ve tweet2 :-")
 dfpv1<-analysis[which(analysis$score==p),]
 print("most +ve tweet3 :-")
 dfng1<-analysis[which(analysis$score==q),]

 p1<-data.frame(dfpv1$score)
 p2<-data.frame(dfpv1$text)
 p3<-cbind(p1,p2) 

 p11<-data.frame(dfng1$score)
 p12<-data.frame(dfng1$text)
 p13<-cbind(p11,p12) 

# collection6 <- "TMost_pos1"
# dt <- sapply(dfpv1$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
# dfpv1$text <- dt  #replace text column by dt
# namespace6 <- paste(db, collection6, sep=".") 
# tw_json <- toJSON(dfpv1$text)
# tw_bson <- mongo.bson.from.JSON(tw_json)
# tw_data <- mongo.insert(m, namespace6, tw_bson)
# print("Erroor7")
 
# collection7 <- "TMost_neg1"
# dt <- sapply(dfng1$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
# dfng1$text <- dt  #replace text column by dt
# namespace7 <- paste(db, collection7, sep=".") 
# tw_json <- toJSON(dfng1$text)
# tw_bson <- mongo.bson.from.JSON(tw_json)
# tw_data <- mongo.insert(m, namespace7, tw_bson)
# print("Erroor8")

 #### Links with some posN neg ####
 tweeter_str <- "https://twitter.com/"
 Link_for_tweets <- raw_data_df$user.screen_name
 path <- paste0(tweeter_str,Link_for_tweets)
 path_df <- data.frame(path)
 analysis_new <- cbind(analysis,path_df)

 print("some +ve tweets  :-")
 df2 <- analysis_new[which(analysis_new$score==3 | analysis_new$score==2 | analysis_new$score==1),]
 p21<-data.frame(df2$score)
 p22<-data.frame(df2$text)
 p23<-cbind(p21,p22)

 collection8 <- paste(ans,"_Some_pos", sep="")
 dt <- sapply(df2$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
 df2$text <- dt  #replace text column by dt
 namespace8 <- paste(db, collection8, sep=".") 
 tw_json <- toJSON(df2)
 tw_bson <- mongo.bson.from.JSON(tw_json)
 tw_data <- mongo.insert(m, namespace8, tw_bson)
 print("Erroor9")

 print("some -ve tweets :-")
 df3 <- analysis_new[which(analysis_new$score==-3 | analysis_new$score==-2 | analysis_new$score==-1),]
 p31<-data.frame(df3$score)
 p32<-data.frame(df3$text)
 p33<-cbind(p31,p32)
 
 collection9 <- paste(ans,"_Some_neg", sep="")
 dt <- sapply(df3$text,function(row) iconv(row, "latin1", "ASCII", sub="")) ## remove smiles
 df3$text <- dt  #replace text column by dt
 namespace9 <- paste(db, collection9, sep=".") 
 tw_json <- toJSON(df3)
 tw_bson <- mongo.bson.from.JSON(tw_json)
 tw_data <- mongo.insert(m, namespace9, tw_bson)
 print("Erroor10")
 print("finished")

}

logistic(ans)