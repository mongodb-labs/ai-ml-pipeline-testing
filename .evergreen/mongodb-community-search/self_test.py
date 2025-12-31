import os
from pymongo import MongoClient
from pymongo.operations import SearchIndexModel

# Connect and get collection
client = MongoClient(os.environ["MONGODB_URI"])
db = client.self_test
movies = db.movies

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

# Create auto-embed index (private preview-style syntax)
movies.create_search_index(
    model=SearchIndexModel(
        name="auto_embed_plot_index",
        type="vectorSearch",
        definition={
            "fields": [
                {
                    "type": "text",
                    "path": "plot",
                    "model": "voyage-3-large",
                },
            ],
        },
    )
)

# Create normal vector index
movies.create_search_index(
    model=SearchIndexModel(
        name="plot_vector_index",
        type="vectorSearch",
        definition={
            "fields": [
                {
                    "type": "vector",
                    "path": "plot_embeddings",
                    "numDimensions": 1024,
                    "similarity": "cosine",
                    "quantization": "none",
                },
            ],
        },
    )
)


# Run vector search aggregation using auto-embed index
cursor = movies.aggregate(
    [
        {
            "$vectorSearch": {
                "index": "auto_embed_plot_index",
                "path": "plot",
                "query": {"text": "movie about couples"},
                "limit": 2,
                "numCandidates": 2,
            }
        }
    ]
)

for doc in cursor:
    print(doc)
    assert doc["title"] == "Breathe"
