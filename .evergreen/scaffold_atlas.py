from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Any, Union

from pymongo import MongoClient
from pymongo.database import Database
from pymongo.operations import SearchIndexModel
from pymongo.results import InsertManyResult

logging.basicConfig()
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG if os.environ.get("DEBUG") else logging.INFO)

DATABASE_NAME = os.environ.get("DATABASE")
CONN_STRING = os.environ.get("CONN_STRING")
REPO_NAME = os.environ.get("REPO_NAME")
DIR = os.environ.get("DIR")
TARGET_DIR = os.environ.get("TARGET_DIR")
DB_PATH = "database"
INDEX_PATH = "indexes"


def upload_data(db: Database, filename: Path) -> None:
    """Upload the contents of the provided file to an Atlas database.

    :param db: The database linking to the Mongo Atlas client
    :param filename: Collection with json contents
    """
    loaded_collection: Union[list[dict[str, Any]], dict[str, Any]]
    collection_name: str = filename.name.removesuffix(".json")
    with filename.open() as f:
        loaded_collection = json.load(f)

    logger.info(
        "Loading %s to Atlas database %s in collection %s",
        filename.name,
        db.name,
        collection_name,
    )
    if not isinstance(loaded_collection, list):
        loaded_collection = [loaded_collection]
    if loaded_collection:
        result: InsertManyResult = db[collection_name].insert_many(loaded_collection)
        logger.debug("Uploaded results for %s: %s", filename.name, result.inserted_ids)
    else:
        logger.debug("Empty collection named %s created", collection_name)
        db.create_collection(collection_name)


def create_index(client: MongoClient, filename: Path) -> None:
    """Create indexes based on the JSONs provided from the index_json files

    Args:
        client (MongoClient): MongoClient
        filename (Path): Index configuration filepath
    """
    with filename.open() as f:
        loaded_index_configuration = json.load(f)

    collection_name = loaded_index_configuration.pop("collectionName")
    database_name = loaded_index_configuration.pop("database")
    index_name = loaded_index_configuration.pop("name")
    index_type = loaded_index_configuration.pop("type", None)

    collection = client[database_name][collection_name]

    search_index = SearchIndexModel(
        loaded_index_configuration, name=index_name, type=index_type
    )
    collection.create_search_index(search_index)


def walk_directory(filepath) -> list[str]:
    """Return all *.json filenames in the DB_PATH directory"""
    database_dir = Path(TARGET_DIR).joinpath(filepath)
    return (
        [file for file in database_dir.iterdir() if file.suffix == ".json"]
        if database_dir.exists()
        else []
    )


def generate_collections(database: Database, collection_jsons: list[Path]) -> None:
    """Generate collections based on the collection_json filepaths

    Args:
        database (Database): Mongo Database
        collection_jsons (list[Path]): List of collection filepaths
    """
    logger.debug(
        "%s collection files found: %s", len(collection_jsons), collection_jsons
    )
    if not collection_jsons:
        return logger.warning(
            "No collections found in %s check if database folder exists", TARGET_DIR
        )
    for collection_json in collection_jsons:
        upload_data(database, collection_json)


def generate_indexes(client: MongoClient, index_jsons: list[Path]) -> None:
    """Generate Search or VectorSearch indexes based on the index_json provided
    TODO: **Improve Documentation to include Local Atlas JSON configuration requirements*

    Args:
        client (MongoClient): MongoClient
        index_jsons (list[Path]): List of index configuration filepaths
    """
    logger.debug("%s index files found: %s", len(index_jsons), index_jsons)
    if not index_jsons:
        return logger.warning(
            "No indexes found in %s check if indexes folder exists", TARGET_DIR
        )
    for index_json in index_jsons:
        create_index(client, index_json)


def main() -> None:
    client = MongoClient(CONN_STRING)
    database = client[DATABASE_NAME]
    collection_jsons = walk_directory(DB_PATH)
    index_jsons = walk_directory(INDEX_PATH)
    generate_collections(database, collection_jsons)
    generate_indexes(client, index_jsons)


if __name__ == "__main__":
    main()
