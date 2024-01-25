from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Any, Union

from pymongo import MongoClient

logger: logging.Logger

DATABASE_NAME = os.environ.get("DATABASE")
CONN_STRING = os.environ.get("CONN_STRING")
REPO_NAME = os.environ.get("REPO_NAME")
DIR = os.environ.get("DIR")
TARGET_DIR = os.environ.get("TARGET_DIR")
DB_PATH = "database"


def scaffold(database: MongoClient, filename: Path) -> None:
    """Take the supplied file contents and upload the data collection

    :param database: The database linking to the Mongo Atlas client
    :type database: MongoClient
    :param filename: Collection with json contents
    :type filename: Path
    """
    loaded_collection: Union[list[dict[str, Any]], dict[str, Any]]
    collection_name: str = filename.name.removesuffix(".json")
    with filename.open() as f:
        loaded_collection = json.load(f)

    logger.info("Loading %s to atlas deployment", filename.name)
    if isinstance(loaded_collection, list):
        database[collection_name].insert_many(loaded_collection)
    else:
        database[collection_name].insert(loaded_collection)


def walk_collection_directory() -> list[str]:
    """Return all *.json filenames in the database directory

    :return: List of json filenames
    :rtype: list[str]
    """
    database_dir = Path(TARGET_DIR).joinpath(DB_PATH)
    return (
        [file for file in database_dir.iterdir() if file.suffix == ".json"]
        if database_dir.exists()
        else []
    )


def main() -> None:
    database = MongoClient(CONN_STRING)[DATABASE_NAME]
    collection_jsons = walk_collection_directory()
    if not collection_jsons:
        return logger.warning("No collection defined for %s", TARGET_DIR)
    for collection_json in collection_jsons:
        scaffold(database, collection_json)


if __name__ == "__main__":
    logger = logging.getLogger(__file__)
    logger.setLevel(logging.INFO)
    main()
