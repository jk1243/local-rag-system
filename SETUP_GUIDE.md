# Local RAG System - Complete Setup Guide

This guide will walk you through setting up your local LLM-based RAG system for personal document management.

## Prerequisites

### 1. Install Docker

Docker is essential for running OpenSearch locally in an isolated environment.

**Installation:**
- Follow the [official Docker installation guide](https://docs.docker.com/get-docker/)
- For Ubuntu/Debian:
  ```bash
  sudo apt-get update
  sudo apt-get install docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

**Verify Installation:**
```bash
docker --version
```

You should see output like: `Docker version 24.x.x`

### 2. Install Ollama

Ollama allows you to run language models locally without requiring the cloud.

**Installation:**
- Download from: https://ollama.ai/download
- Or for Linux:
  ```bash
  curl -fsSL https://ollama.ai/install.sh | sh
  ```

**Verify Installation:**
```bash
ollama --version
```

**Test with a model:**
```bash
ollama run llama3.2:1b
```

You can explore more models at: https://ollama.ai/library

### 3. Python 3.11

This project requires Python 3.11. Check your version:
```bash
python3 --version
```

If you need to install Python 3.11, download it from: https://www.python.org/downloads/

## Setup Steps

### Step 1: Set Up OpenSearch and OpenSearch Dashboard

#### Pull Docker Images
```bash
docker pull opensearchproject/opensearch:2.11.0
docker pull opensearchproject/opensearch-dashboards:2.11.0
```

#### Run OpenSearch Container
```bash
docker run -d --name opensearch \
  -p 9200:9200 -p 9600:9600 \
  -e "discovery.type=single-node" \
  -e "DISABLE_SECURITY_PLUGIN=true" \
  opensearchproject/opensearch:2.11.0
```

#### Run OpenSearch Dashboard Container
```bash
docker run -d --name opensearch-dashboards \
  -p 5601:5601 \
  --link opensearch:opensearch \
  -e "OPENSEARCH_HOSTS=http://opensearch:9200" \
  -e "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" \
  opensearchproject/opensearch-dashboards:2.11.0
```

**Verify:** Open http://localhost:5601 in your browser to access the OpenSearch Dashboard.

### Step 2: Enable Hybrid Search in OpenSearch

Hybrid search combines traditional search (BM25) with vector-based semantic search.

#### Create Search Pipeline

Run this command in your terminal:
```bash
curl -XPUT "http://localhost:9200/_search/pipeline/nlp-search-pipeline" -H 'Content-Type: application/json' -d'
{
  "description": "Post processor for hybrid search",
  "phase_results_processors": [
    {
      "normalization-processor": {
        "normalization": {
          "technique": "min_max"
        },
        "combination": {
          "technique": "arithmetic_mean",
          "parameters": {
            "weights": [
              0.3,
              0.7
            ]
          }
        }
      }
    }
  ]
}
'
```

**Alternative:** Use the OpenSearch Dashboard Dev Tools:
1. Go to http://localhost:5601
2. Navigate to Dev Tools
3. Paste and run:
```json
PUT /_search/pipeline/nlp-search-pipeline
{
  "description": "Post processor for hybrid search",
  "phase_results_processors": [
    {
      "normalization-processor": {
        "normalization": {
          "technique": "min_max"
        },
        "combination": {
          "technique": "arithmetic_mean",
          "parameters": {
            "weights": [
              0.3,
              0.7
            ]
          }
        }
      }
    }
  ]
}
```

### Step 3: Install Python Dependencies

Create a virtual environment (recommended):
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Install dependencies:
```bash
pip install -r requirements.txt
```

### Step 4: Configure Application Settings

Edit `src/constants.py` to customize your setup:

**Key Configuration Options:**

1. **EMBEDDING_MODEL_PATH**:
   - Default: `"sentence-transformers/all-mpnet-base-v2"`
   - For faster loading, download the model locally and point to the folder
   - Example: `"embedding_model/"` (if you save the model in this folder)

2. **EMBEDDING_DIMENSION**:
   - For `all-mpnet-base-v2`: 768
   - For `all-MiniLM-L12-v2`: 384
   - Must match your chosen embedding model

3. **TEXT_CHUNK_SIZE**:
   - Default: 300 characters
   - Smaller chunks = better retrieval accuracy but slower processing
   - Adjust based on your document types

4. **OLLAMA_MODEL_NAME**:
   - Default: `"llama3.2:1b"`
   - Can use any model from Ollama library
   - Larger models = better responses but slower

### Step 5: Download Embedding Model (Optional but Recommended)

To avoid downloading the embedding model every time you run the app:

```bash
python3 -c "from sentence_transformers import SentenceTransformer; model = SentenceTransformer('sentence-transformers/all-mpnet-base-v2'); model.save('embedding_model/')"
```

Then update `src/constants.py`:
```python
EMBEDDING_MODEL_PATH = "embedding_model/"
```

### Step 6: Install Tesseract OCR

For PDF text extraction with OCR capabilities:

**Ubuntu/Debian:**
```bash
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

**Windows:**
- Download installer from: https://github.com/UB-Mannheim/tesseract/wiki

### Step 7: Pull Ollama Model

Before running the application, pull the LLM model:
```bash
ollama pull llama3.2:1b
```

Or try other models:
```bash
ollama pull llama3.2:3b
ollama pull mistral
```

### Step 8: Launch the Application

Start the Streamlit application:
```bash
streamlit run Welcome.py
```

The application will be available at: http://localhost:8501

**Note:** The first run may take a few minutes to load the embedding models.

## Using the Application

### Uploading Documents
1. Navigate to the "Upload Documents" page
2. Drag and drop PDF files
3. The system will:
   - Extract text using OCR
   - Split text into chunks
   - Generate embeddings
   - Index in OpenSearch

### Chatbot Interaction
1. Go to the "Chatbot" page
2. Enable RAG mode for document-aware responses
3. Ask questions about your uploaded documents
4. Adjust settings:
   - Number of search results
   - LLM temperature
   - Search mode

## Troubleshooting

### Docker Issues
- **Container won't start:** Check if ports 9200, 9600, 5601 are available
- **Permission denied:** Run with `sudo` or add user to docker group
  ```bash
  sudo usermod -aG docker $USER
  ```

### OpenSearch Issues
- **Can't connect:** Verify containers are running: `docker ps`
- **Port conflicts:** Stop conflicting services or change ports

### Ollama Issues
- **Model not found:** Pull the model first: `ollama pull <model-name>`
- **Slow responses:** Try a smaller model like `llama3.2:1b`

### Python Issues
- **Import errors:** Ensure virtual environment is activated
- **Version conflicts:** Use Python 3.11 exactly

### OCR Issues
- **Tesseract not found:** Verify installation with `tesseract --version`
- **Poor text extraction:** PDF may be scanned at low quality

## Advanced Customization

### Use Larger LLMs
For better responses, try larger models:
```bash
ollama pull llama3.2:3b
ollama pull llama3:8b
```

Update `src/constants.py`:
```python
OLLAMA_MODEL_NAME = "llama3:8b"
```

### Fine-tune Embedding Models
- Use domain-specific embedding models
- Fine-tune on your document corpus
- See: https://www.sbert.net/docs/training/overview.html

### Custom OCR Processing
Modify `src/ocr.py` to:
- Add preprocessing steps
- Handle complex layouts
- Extract tables and images

### Adjust Chunking Strategy
Edit `pages/2_📄_Upload_Documents.py` to:
- Change chunk size
- Add overlap between chunks
- Use semantic chunking

### Add Metadata
Enhance OpenSearch indexing in `src/ingestion.py`:
- Add page numbers
- Extract entities
- Add document summaries
- Include timestamps

### Customize Prompts
Modify `src/chat.py` to:
- Change prompt templates
- Adjust context formatting
- Fine-tune response style

## Useful Commands

### Docker Management
```bash
# List running containers
docker ps

# Stop containers
docker stop opensearch opensearch-dashboards

# Start containers
docker start opensearch opensearch-dashboards

# Remove containers
docker rm opensearch opensearch-dashboards

# View logs
docker logs opensearch
docker logs opensearch-dashboards
```

### Ollama Management
```bash
# List installed models
ollama list

# Pull a model
ollama pull <model-name>

# Remove a model
ollama rm <model-name>

# Run model directly
ollama run <model-name>
```

## Resources

- [OpenSearch Documentation](https://opensearch.org/docs/)
- [Ollama Library](https://ollama.ai/library)
- [Sentence Transformers](https://www.sbert.net/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [Original Blog Post - Part 1](https://jamwithai.substack.com/p/build-a-local-llm-based-rag-system)
- [Original Blog Post - Part 2](https://jamwithai.substack.com/p/build-a-local-llm-based-rag-system-628)

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the blog posts linked in the README
- Open an issue on GitHub

Happy building!
