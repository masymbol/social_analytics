package com.tweets;

import java.net.UnknownHostException;
import java.util.List;
import java.util.Scanner;

import twitter4j.Query;
import twitter4j.QueryResult;
import twitter4j.Status;
import twitter4j.Twitter;
import twitter4j.TwitterException;
import twitter4j.TwitterFactory;

import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class TwitterApp {
	public static void main(String[] args) throws TwitterException,
			UnknownHostException, MongoException {

		// create scanner object
		Scanner sc = new Scanner(System.in);
		System.out.print("enter the keyword : ");
		String keyword = sc.next();
		// create object to twitter class
		Twitter twitter = new TwitterFactory().getInstance();
		// create object for query
		Query query = new Query(keyword);
		// get result set from query object
		QueryResult result = twitter.search(query);
		// create object to mongo
		Mongo mongo;
		mongo = new Mongo("localhost", 27017);
		// get database name
		DB db = mongo.getDB("testtweets");
		// get collection name
		DBCollection collection = db.getCollection(keyword);

		BasicDBObject document;
		do {
			// list all tweets
			List<Status> tweets = result.getTweets();
			// iterate the tweets
			for (Status tweet : tweets) {

				// create document object
				document = new BasicDBObject();

				// status data appending to document object
				document.append("createdAt", tweet.getCreatedAt());
				document.append("id", tweet.getId());
				document.append("Text", tweet.getText());
				document.append("source", tweet.getSource());
				document.append("isTruncated", tweet.isTruncated());
				document.append("inReplyToStatusId",
						tweet.getInReplyToStatusId());
				document.append("inReplyToUserId", tweet.getInReplyToUserId());
				document.append("isFavorited", tweet.isFavorited());
				document.append("inReplyToScreenName",
						tweet.getInReplyToScreenName());
				if(tweet.getGeoLocation() != null)
				{
				 document.append("geoLocation-latitude", tweet.getGeoLocation().getLatitude());
				 document.append("geoLocation-longitude",tweet.getGeoLocation().getLongitude());
				}
				if(tweet.getPlace() != null)
				{
				   document.append("place-name", tweet.getPlace().getName());
				   document.append("place-streetAddress", tweet.getPlace().getStreetAddress());
				   document.append("place-countryCode",tweet.getPlace().getCountryCode());
				   document.append("place-id",tweet.getPlace().getId());
				   document.append("country",tweet.getPlace().getCountry());
				   document.append("placeType",tweet.getPlace().getPlaceType());
				   document.append("url",tweet.getPlace().getURL());
				}
				document.append("retweetCount", tweet.getRetweetCount());
				document.append("isPossiblySensitive",
						tweet.isPossiblySensitive());
				document.append("currentUserRetweetId",
						tweet.getCurrentUserRetweetId());

				// document.append("contributorsIDs",tweet.getContributors());
				// document.append("hashtagEntities",tweet.getHashtagEntities());
				// document.append("mediaEntities",tweet.getMediaEntities());

				// user data appending to document object

				document.append("user", tweet.getUser().getId());
				document.append("name", tweet.getUser().getName());
				document.append("screenName", tweet.getUser().getScreenName());
				document.append("location", tweet.getUser().getLocation());
				document.append("description", tweet.getUser().getDescription());
				document.append("isContributorsEnabled", tweet.getUser()
						.isContributorsEnabled());
				document.append("profileImageUrl", tweet.getUser()
						.getProfileImageURL());
				document.append("profileImageUrlHttps", tweet.getUser()
						.getProfileImageURLHttps());
				document.append("url", tweet.getUser().getURL());
				document.append("isProtected", tweet.getUser().isProtected());
				document.append("followersCount", tweet.getUser()
						.getFollowersCount());
				document.append("status", tweet.getUser().getStatus());
				document.append("profileBackgroundColor", tweet.getUser()
						.getProfileBackgroundColor());
				document.append("profileTextColor", tweet.getUser()
						.getProfileTextColor());
				document.append("profileLinkColor", tweet.getUser()
						.getProfileLinkColor());
				document.append("profileSidebarFillColor", tweet.getUser()
						.getProfileSidebarFillColor());
				document.append("profileSidebarBorderColor", tweet.getUser()
						.getProfileSidebarBorderColor());
				document.append("profileUseBackgroundImage", tweet.getUser()
						.isProfileUseBackgroundImage());
				document.append("showAllInlineMedia", tweet.getUser()
						.isShowAllInlineMedia());
				document.append("friendsCount", tweet.getUser()
						.getFriendsCount());
				document.append("user createdAt", tweet.getUser()
						.getCreatedAt());
				document.append("favouritesCount", tweet.getUser()
						.getFavouritesCount());
				document.append("utcOffset", tweet.getUser().getUtcOffset());
				document.append("timeZone", tweet.getUser().getTimeZone());
				document.append("profileBackgroundImageUrl", tweet.getUser()
						.getProfileBackgroundImageURL());
				document.append("profileBackgroundImageUrlHttps", tweet
						.getUser().getProfileBackgroundImageUrlHttps());
				document.append("profileBackgroundTiled", tweet.getUser()
						.isProfileBackgroundTiled());
				document.append("lang", tweet.getUser().getLang());
				document.append("statusesCount", tweet.getUser()
						.getStatusesCount());
				document.append("isGeoEnabled", tweet.getUser().isGeoEnabled());
				document.append("isVerified", tweet.getUser().isVerified());
				document.append("translator", tweet.getUser().isTranslator());
				document.append("listedCount", tweet.getUser().getListedCount());
				document.append("isFollowRequestSent", tweet.getUser()
						.isFollowRequestSent());

				System.out.println(tweet);

				collection.insert(document);

				query = result.nextQuery();

				if (query != null) {
					result = twitter.search(query);
				}
			}

		} while (query != null);

	}
}