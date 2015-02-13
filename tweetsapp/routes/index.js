var express = require('express');
var fs = require('fs');
var router = express.Router();
var flash = require('./flash');
var exec = require('child_process').exec;
var time = require('time');
var mongo = require('mongodb');
var host = "127.0.0.1";
var port = mongo.Connection.DEFAULT_PORT;
var db = new mongo.Db("analytics", new mongo.Server(host, port, {}));
var tweetCollection;
var keyword ;

db.open(function(error){
	if(error) {
		console.log(error);
	}
	else {
		console.log("We are connected! " + host + ":" + port);
	}
});


router.get('/',function (req,res) {
	
	var message = req.flash('info');
	res.render('index', { title: 'Dashboard Page', req:req, message:message});
});



router.post('/preview',function(req,res){
	
	var searchQuery = req.body.search;
	searchQuery = searchQuery.toLowerCase();
	keyword = searchQuery;
	var working_dir = process.env.PWD;
	
	console.log('python script started...');
	
	exec("python " +working_dir+ "/analysis/Twitter_fetch_mongo.py " +searchQuery, function(err, data){
			if (err){
						console.log("Error while searching "+ err); 
					}else{
						console.log("searching  "+searchQuery+"...");
					}
				});
	console.log('python script running under background...');
	
	// setTimeout(function() {

	// 	exec("Rscript "+working_dir+"/analysis/Twitter_py_mongo_sentimentScore.R "+searchQuery,function(err,data){
	// 		if (err){
	// 					console.log("unable to get data from mongodb"+ err); 
	// 		}
	// 			else{
	// 					console.log("sentiment analysis "+searchQuery+"...");
	// 			}
	// 	});
	// },2000);
	
	// setTimeout(function() {
	// 	exec("Rscript " +working_dir+"/analysis/Twitter_py_mongo_wordcloud.R " +searchQuery, function(err,data){
	// 		if (err){
	// 					console.log("unable to get data from mongodb"+ err); 
	// 			}else{
	// 					console.log(" wordcloud analysis "+searchQuery+"...");
	// 				 }
	// 		});
	// },2000);
	console.log(keyword);
	db.collection(keyword, function(error, collection){
		tweetCollection = collection;
		console.log(tweetCollection);
	});
	res.redirect('/preview');
});


router.get('/preview',function(req,res){
	console.log(keyword);
	var content = [];
	setTimeout(function(){

		// Top 10 Tweets
			getTweets(function(tweets){

				tweets.forEach(function(tweet) {
					console.log("adding tweets .. ")
					tweet = tweet.user.screen_name + ":" + tweet.text;
					content.push(tweet);
					console.log(tweet);
				});
				console.log("sending tweets ...");
			});

		res.render('preview',{ title:'Dashboard Page', req:req, content:content,keyword:keyword});
	},2000);


});

function getTweets(callback) {
	console.log("getting tweets")
	tweetCollection.find({}, {"limit":10}, function(error, cursor) {
		cursor.toArray(function(error, tweets) {
			callback(tweets);
		});
	});
}

module.exports = router;