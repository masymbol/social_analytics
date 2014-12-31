package com.youtube;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.UnknownHostException;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestInitializer;
import com.google.api.services.youtube.YouTube;
import com.google.api.services.youtube.model.ResourceId;
import com.google.api.services.youtube.model.SearchListResponse;
import com.google.api.services.youtube.model.SearchResult;
import com.google.api.services.youtube.model.Thumbnail;
import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class YouTubeApp {

	/**
	 * Define a global variable that identifies the name of a file that contains
	 * the developer's API key.
	 */
	private static final String PROPERTIES_FILENAME = "resourses/youtube.properties";
	static String inputQuery = "";
	private static final long NUMBER_OF_VIDEOS_RETURNED = 49;

	/**
	 * Define a global instance of a Youtube object, which will be used to make
	 * YouTube Data API requests.
	 */
	private static YouTube youtube;

	/**
	 * Initialize a YouTube object to search for videos on YouTube. Then display
	 * the name and thumbnail image of each video in the result set.
	 * 
	 * @param args
	 *            command line args.
	 */
	public static void main(String[] args) {
		// Read the developer key from the properties file.
		Properties properties = new Properties();
		try {
			InputStream in = YouTubeApp.class.getResourceAsStream("/"
					+ PROPERTIES_FILENAME);
			properties.load(in);

		} catch (IOException e) {
			System.err.println("There was an error reading "
					+ PROPERTIES_FILENAME + ": " + e.getCause() + " : "
					+ e.getMessage());
			System.exit(1);
		}

		try {
			// This object is used to make YouTube Data API requests. The last
			// argument is required, but since we don't need anything
			// initialized when the HttpRequest is initialized, we override
			// the interface and provide a no-op function.
			youtube = new YouTube.Builder(Auth.HTTP_TRANSPORT,
					Auth.JSON_FACTORY, new HttpRequestInitializer() {
						public void initialize(HttpRequest request)
								throws IOException {
						}
					}).setApplicationName("youtube-cmdline-search-sample")
					.build();

			// Prompt the user to enter a query term.
			String queryTerm = getInputQuery();

			// Define the API request for retrieving search results.
			YouTube.Search.List search = youtube.search().list("id,snippet");

			// Set your developer key from the {{ Google Cloud Console }} for
			// non-authenticated requests. See:
			// {{ https://cloud.google.com/console }}
			String apiKey = properties.getProperty("youtube.apikey");
			search.setKey(apiKey);
			search.setQ(queryTerm);

			// Restrict the search results to only include videos. See:
			// https://developers.google.com/youtube/v3/docs/search/list#type
			search.setType("video");

			// To increase efficiency, only retrieve the fields that the
			// application uses.
			search.setFields("items(id/kind,id/videoId,snippet/title,snippet/thumbnails/default/url)");
			search.setMaxResults(NUMBER_OF_VIDEOS_RETURNED);

			// Call the API and print results.
			SearchListResponse searchResponse = search.execute();
			List<SearchResult> searchResultList = searchResponse.getItems();
			if (searchResultList != null) {
				prettyPrint(searchResultList.iterator(), queryTerm);
			}
		} catch (GoogleJsonResponseException e) {
			System.err.println("There was a service error: "
					+ e.getDetails().getCode() + " : "
					+ e.getDetails().getMessage());
		} catch (IOException e) {
			System.err.println("There was an IO error: " + e.getCause() + " : "
					+ e.getMessage());
		} catch (Throwable t) {
			t.printStackTrace();
		}
	}

	/*
	 * Prompt the user to enter a query term and return the user-specified term.
	 */
	private static String getInputQuery() throws IOException {

		inputQuery = "";

		System.out.print("Please enter a search term: ");
		BufferedReader bReader = new BufferedReader(new InputStreamReader(
				System.in));
		inputQuery = bReader.readLine();

		if (inputQuery.length() < 1) {
			// Use the string "YouTube Developers Live" as a default.
			inputQuery = "YouTube Developers Live";
		}
		return inputQuery;
	}

	/*
	 * Prints out all results in the Iterator. For each result, print the title,
	 * video ID, and thumbnail.
	 * 
	 * @param iteratorSearchResults Iterator of SearchResults to print
	 * 
	 * @param query Search query (String)
	 */
	private static void prettyPrint(
			Iterator<SearchResult> iteratorSearchResults, String query)
			throws UnknownHostException, MongoException {

		System.out
				.println("\n=============================================================");
		System.out.println("   First " + NUMBER_OF_VIDEOS_RETURNED
				+ " videos for search on \"" + query + "\".");
		System.out
				.println("=============================================================\n");

		if (!iteratorSearchResults.hasNext()) {
			System.out.println(" There aren't any results for your query.");
		}

		while (iteratorSearchResults.hasNext()) {

			SearchResult singleVideo = iteratorSearchResults.next();
			ResourceId rId = singleVideo.getId();

			// Confirm that the result represents a video. Otherwise, the
			// item will not contain a video ID.
			if (rId.getKind().equals("youtube#video")) {

				Thumbnail thumbnail = singleVideo.getSnippet().getThumbnails()
						.getDefault();

				System.out.println("Video Id : " + "https://www.youtube.com/watch?v="+ rId.getVideoId());
				System.out.println("Title : "
						+ singleVideo.getSnippet().getTitle());
				System.out.println("Thumbnail : " + thumbnail.getUrl());
				System.out
						.println("\n-------------------------------------------------------------\n");

				Mongo mongo;
				mongo = new Mongo("localhost", 27017);
				// get database name
				DB db = mongo.getDB("youtubevedios");
				// get collection name
				DBCollection collection = db.getCollection(inputQuery);

				BasicDBObject document;

				document = new BasicDBObject();

				document.append("Video Id : ", "https://www.youtube.com/watch?v="+ rId.getVideoId());
				document.append("Title : ", singleVideo.getSnippet().getTitle());
				document.append("Thumbnail : ", thumbnail.getUrl());
				collection.insert(document);

				// System.out.println("Kind : " + singleVideo.getKind());
				// System.out.println("Etag : " + singleVideo.getEtag());
				//
				// System.out.println("getKind : "+ rId.getKind());

				// System.out.println("ChannelId : " + rId.getChannelId());
				// System.out.println("PlaylistId : "+ rId.getPlaylistId());
				//
				// System.out.println("publishedAt : " +
				// singleVideo.getSnippet().getPublishedAt());
				// System.out.println("ChannelId : " +
				// singleVideo.getSnippet().getChannelId());

				// System.out.println("description : " +
				// singleVideo.getSnippet().getDescription());

				// System.out.println("width : " + thumbnail.getWidth());
				// System.out.println("height : " + thumbnail.getHeight());
				//
				//
				// System.out.println("ChannelTitle : " +
				// singleVideo.getSnippet().getChannelTitle());
				// System.out.println("LiveBroadcastContent : " +
				// singleVideo.getSnippet().getLiveBroadcastContent());

			}
		}
	}
}