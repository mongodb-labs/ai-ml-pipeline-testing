import os
from pymongo import MongoClient
from pymongo.operations import SearchIndexModel
from time import sleep

print("Beginning simple test of vectorSearch with autoEmbed index.")

# Connect and create collection
client = MongoClient(os.environ["MONGODB_URI"])
db = client.self_test
movies = db.create_collection("movies")

# Create auto-embed index (public preview-style syntax)
movies.create_search_index(
    model=SearchIndexModel(
        name="auto_embed_plot_index",
        type="vectorSearch",
        definition={
            "fields": [
                {
                    "type": "autoEmbed",
                    "path": "plot",
                    "model": "voyage-4",
                    "modality": "text",
                },
            ],
        },
    )
)
sleep(10)

# Insert documents
movies.insert_many(
    [
        {
            "cast": ["Cillian Murphy", "Emily Blunt", "Matt Damon"],
            "director": "Christopher Nolan",
            "genres": ["Biography", "Drama", "History"],
            "imdb": {
                "rating": 8.3,
                "votes": 680000,
            },
            "plot": "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.",
            "runtime": 180,
            "title": "Oppenheimer",
            "year": 2023,
        },
        {
            "cast": ["Andrew Garfield", "Claire Foy", "Hugh Bonneville"],
            "director": "Andy Serkis",
            "genres": ["Biography", "Drama", "Romance"],
            "imdb": {
                "rating": 7.2,
                "votes": 42000,
            },
            "plot": "The inspiring true love story of Robin and Diana Cavendish, an adventurous couple who refuse to give up in the face of a devastating disease.",
            "runtime": 118,
            "title": "Breathe",
            "year": 2017,
        },
    ]
)
sleep(10)

# Run vector search aggregation using auto-embed index
search_results = list(
    movies.aggregate(
        [
            {
                "$vectorSearch": {
                    "index": "auto_embed_plot_index",
                    "path": "plot",
                    "query": {"text": "movie about couples"},
                    "limit": 1,
                    "numCandidates": 10,
                }
            }
        ]
    )
)

print(f"{len(search_results)=}")
assert len(search_results) == 1
for doc in search_results:
    print(doc)
    assert doc["title"] == "Breathe"
