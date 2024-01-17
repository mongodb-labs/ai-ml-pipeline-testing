import os

from pymongo import MongoClient

client = MongoClient(os.environ["CONN_STRING"])
client[os.environ["DATABASE"]].create_collection(os.environ.get("COLLECTION"))
