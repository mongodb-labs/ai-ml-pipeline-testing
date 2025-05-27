import os
from crewai import Agent
from crewai import Task
from crewai import Crew, Process
from crewai_tools import MongoDBVectorSearchTool
from langchain_community.document_loaders import PyPDFLoader
import time

# Pre-populate a collection and an index
print("Creating collection...")
conn_string = os.environ.get(
    "MONGODB_URI", "mongodb://localhost:27017?directConnection=true"
)
database_name = "crewai_test_db"
collection_name = "vector_test"

tool = MongoDBVectorSearchTool(
    connection_string=conn_string,
    database_name=database_name,
    collection_name=collection_name,
)
coll = tool._coll
coll.delete_many({})

# Insert documents from a pdf.
print("Loading documents...")
loader = PyPDFLoader("https://arxiv.org/pdf/2303.08774.pdf")
tool.add_texts([i.page_content for i in loader.load()])

print("Creating vector index...")
if not any([ix["name"] == "vector_index" for ix in coll.list_search_indexes()]):
    tool.create_vector_search_index(dimensions=3072)

# Create the MongoDB tool
print("Creating tool and waiting for index to be complete...")

# Wait for index to be complete.
n_docs = coll.count_documents({})
start = time.monotonic()
while time.monotonic() - start <= 60:
    if len(tool._run(query="sandwich", limit=n_docs, oversampling_factor=1)) == n_docs:
        break
    else:
        time.sleep(1)

# Assemble a crew
researcher = Agent(
    role="AI Accuracy Researcher",
    goal="Find and extract key information from a technical document",
    backstory="You're specialized in analyzing technical content to extract insights and answers",
    verbose=False,
    tools=[tool],
)
research_task = Task(
    description="Research information in a technical document",
    expected_output="A summary of the accuracy of GPT-4",
    agent=researcher,
)
crew = Crew(
    agents=[researcher],
    tasks=[research_task],
    process=Process.sequential,
    verbose=False,
)

# Get the result and assert something about the results
print("Running the crew...")
result = crew.kickoff()
assert "hallucinations" in result.raw.lower()
assert "GPT-4" in result.raw
