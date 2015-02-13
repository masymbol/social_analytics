import json
import pymongo
import tweepy
__author__ = 'nixCraft'
import sys
from pymongo import Connection
connection = Connection()
 

consumer_key = "hNbDsAu6twdczmmUenJEBMkwl"
consumer_secret = "2FkGXeWhUX7s2YUFlV0JaGdIRmsdGg4RaG0pzmune7qcUaN595"
access_key = "2608974788-ujlln3FdR0DCNOctxaD3jsCdFq049e8goj6u0bL"
access_secret = "awI57sWB0MNfbb0125igyi9Rp9FyyM5XAbmVpnmvIV3Rp"

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_key, access_secret)
api = tweepy.API(auth)


class CustomStreamListener(tweepy.StreamListener):
    def __init__(self, api):
        self.api = api
        super(tweepy.StreamListener, self).__init__()

        #self.db = pymongo.MongoClient().sachin
        self.db = connection[str(sys.argv[1])] #Creation of dynamic Database

    def on_data(self, tweet):
        self.db[str(sys.argv[1])].insert(json.loads(tweet))

    def on_error(self, status_code):
        return True # Don't kill the stream

    def on_timeout(self):
        return True # Don't kill the stream


sapi = tweepy.streaming.Stream(auth, CustomStreamListener(api))
sapi.filter(track=[str(sys.argv[1])])