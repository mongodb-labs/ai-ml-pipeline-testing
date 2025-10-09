import os
from crewai import Agent
from crewai import Task
from crewai import Crew, Process, LLM
from crewai_tools import MongoDBVectorSearchTool, MongoDBVectorSearchConfig
from langchain_community.document_loaders import PyPDFLoader
import time

# Set environment as LiteLLM expects
os.environ["AZURE_API_KEY"] = os.environ["AZURE_OPENAI_API_KEY"]
os.environ["AZURE_API_BASE"] = os.environ["AZURE_OPENAI_ENDPOINT"]
os.environ["AZURE_API_VERSION"] = os.environ["OPENAI_API_VERSION"]

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
    tool.create_vector_search_index(dimensions=1536, auto_index_timeout=60)

# Create the MongoDB tool
print("Creating tool and waiting for index to be complete...")

# Wait for index to be complete.
n_docs = coll.count_documents({})
tool.query_config = MongoDBVectorSearchConfig(limit=n_docs, oversampling_factor=1)
start = time.monotonic()
while time.monotonic() - start <= 60:
    if len(tool._run("sandwich")) == n_docs:
        break
    else:
        time.sleep(1)

# Assemble a crew
researcher = Agent(
    role="AI Accuracy Researcher",
    goal="Find and extract key information from a technical document",
    backstory="You're specialized in analyzing technical content to extract insights and answers",
    verbose=True,
    tools=[tool],
    llm=LLM(model="azure/gpt-4o", seed=12345),
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
    verbose=True,
)

# Get the result and assert something about the results
print("Running the crew...")
result = crew.kickoff()
text = result.raw.lower()
assert "limitations" in text, text
assert "GPT-4" in result.raw
