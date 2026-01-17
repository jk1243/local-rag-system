#!/bin/bash
# Quick Start Script for Local RAG System
# This script will guide you through the complete setup process

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo "========================================="
echo "  Local RAG System - Quick Start"
echo "========================================="
echo ""
echo "This script will help you set up your local"
echo "LLM-based RAG system for personal documents."
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to pause for user
pause() {
    read -p "Press Enter to continue..." -r
    echo
}

# Step 1: Check Prerequisites
echo -e "${BLUE}Step 1: Checking Prerequisites${NC}"
echo "========================================="

# Check Docker
if command_exists docker; then
    docker_version=$(docker --version)
    echo -e "${GREEN}✓ Docker installed: $docker_version${NC}"
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Python
if command_exists python3; then
    python_version=$(python3 --version)
    echo -e "${GREEN}✓ Python installed: $python_version${NC}"
else
    echo -e "${RED}✗ Python 3 is not installed${NC}"
    echo "Please install Python 3.11 from: https://www.python.org/downloads/"
    exit 1
fi

# Check Ollama
if command_exists ollama; then
    ollama_version=$(ollama --version 2>&1 || echo "installed")
    echo -e "${GREEN}✓ Ollama installed: $ollama_version${NC}"
else
    echo -e "${YELLOW}⚠ Ollama is not installed${NC}"
    echo "Ollama is required for running local LLMs."
    echo "Install from: https://ollama.ai/download"
    echo ""
    read -p "Do you want to continue without Ollama? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Tesseract (optional)
if command_exists tesseract; then
    tesseract_version=$(tesseract --version 2>&1 | head -n1)
    echo -e "${GREEN}✓ Tesseract OCR installed: $tesseract_version${NC}"
else
    echo -e "${YELLOW}⚠ Tesseract OCR is not installed${NC}"
    echo "Tesseract is recommended for better PDF text extraction."
    echo "Install: sudo apt-get install tesseract-ocr (Ubuntu/Debian)"
    echo "         brew install tesseract (macOS)"
fi

echo ""
pause

# Step 2: Setup OpenSearch
echo -e "${BLUE}Step 2: Setting up OpenSearch${NC}"
echo "========================================="
echo "OpenSearch is the vector database for storing document embeddings."
echo ""

if docker ps | grep -q opensearch; then
    echo -e "${GREEN}OpenSearch is already running${NC}"
    read -p "Do you want to restart it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./setup_opensearch.sh
    fi
else
    read -p "Start OpenSearch now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./setup_opensearch.sh
    else
        echo -e "${YELLOW}Skipping OpenSearch setup${NC}"
        echo "You can run it later with: ./setup_opensearch.sh"
    fi
fi

echo ""
pause

# Step 3: Configure Hybrid Search
echo -e "${BLUE}Step 3: Configuring Hybrid Search Pipeline${NC}"
echo "========================================="
echo "The hybrid search pipeline combines traditional and semantic search."
echo ""

if curl -s http://localhost:9200/_search/pipeline/nlp-search-pipeline 2>/dev/null | grep -q "nlp-search-pipeline"; then
    echo -e "${GREEN}Hybrid search pipeline is already configured${NC}"
else
    if curl -s http://localhost:9200 > /dev/null 2>&1; then
        read -p "Configure hybrid search now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./configure_hybrid_search.sh
        else
            echo -e "${YELLOW}Skipping hybrid search configuration${NC}"
            echo "You can run it later with: ./configure_hybrid_search.sh"
        fi
    else
        echo -e "${YELLOW}OpenSearch is not running. Skipping hybrid search configuration.${NC}"
    fi
fi

echo ""
pause

# Step 4: Install Python Dependencies
echo -e "${BLUE}Step 4: Installing Python Dependencies${NC}"
echo "========================================="
echo "This will install all required Python packages."
echo "Note: This may take 5-10 minutes and download ~1.5GB of packages."
echo ""

read -p "Install Python dependencies now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if virtual environment is recommended
    if [ ! -d "venv" ]; then
        echo ""
        echo -e "${YELLOW}Tip: It's recommended to use a virtual environment${NC}"
        read -p "Create a virtual environment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Creating virtual environment..."
            python3 -m venv venv
            echo -e "${GREEN}✓ Virtual environment created${NC}"
            echo "Activating virtual environment..."
            source venv/bin/activate
            echo -e "${GREEN}✓ Virtual environment activated${NC}"
        fi
    else
        echo "Virtual environment already exists"
        read -p "Activate and use it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            source venv/bin/activate
            echo -e "${GREEN}✓ Virtual environment activated${NC}"
        fi
    fi

    echo ""
    echo "Installing dependencies (this may take a while)..."
    pip install -r requirements.txt
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${YELLOW}Skipping dependency installation${NC}"
    echo "You can install them later with: pip install -r requirements.txt"
fi

echo ""
pause

# Step 5: Pull Ollama Model
if command_exists ollama; then
    echo -e "${BLUE}Step 5: Pulling Ollama LLM Model${NC}"
    echo "========================================="
    echo "Recommended model: llama3.2:1b (fast, ~1.3GB)"
    echo "Alternative models:"
    echo "  - llama3.2:3b (better quality, ~3GB)"
    echo "  - mistral (good balance, ~4GB)"
    echo ""

    if ollama list | grep -q "llama3.2:1b"; then
        echo -e "${GREEN}✓ llama3.2:1b is already downloaded${NC}"
    else
        read -p "Pull llama3.2:1b model now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ollama pull llama3.2:1b
            echo -e "${GREEN}✓ Model downloaded${NC}"
        else
            echo -e "${YELLOW}Skipping model download${NC}"
            echo "You can pull it later with: ollama pull llama3.2:1b"
        fi
    fi

    echo ""
    pause
fi

# Step 6: Configure Application
echo -e "${BLUE}Step 6: Application Configuration${NC}"
echo "========================================="
echo "Current configuration (src/constants.py):"
echo ""

if [ -f "src/constants.py" ]; then
    echo "EMBEDDING_MODEL: $(grep 'EMBEDDING_MODEL_PATH' src/constants.py | head -n1)"
    echo "EMBEDDING_DIMENSION: $(grep 'EMBEDDING_DIMENSION' src/constants.py | head -n1)"
    echo "TEXT_CHUNK_SIZE: $(grep 'TEXT_CHUNK_SIZE' src/constants.py | head -n1)"
    echo "OLLAMA_MODEL: $(grep 'OLLAMA_MODEL_NAME' src/constants.py | head -n1)"
    echo ""
    echo "These settings are already configured with sensible defaults."
    echo "See SETUP_GUIDE.md for customization options."
else
    echo -e "${RED}✗ src/constants.py not found${NC}"
fi

echo ""
pause

# Step 7: Launch Application
echo -e "${BLUE}Step 7: Launch the Application${NC}"
echo "========================================="
echo ""

read -p "Start the Streamlit application now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Starting application...${NC}"
    echo ""
    echo "The application will open in your browser at http://localhost:8501"
    echo ""
    echo "Note: First launch may take 1-2 minutes to load embedding models."
    echo ""
    echo "To stop the application, press Ctrl+C"
    echo ""
    echo "========================================="

    # Check if in virtual environment
    if [ -d "venv" ] && [ -z "$VIRTUAL_ENV" ]; then
        echo -e "${YELLOW}Activating virtual environment...${NC}"
        source venv/bin/activate
    fi

    streamlit run Welcome.py
else
    echo ""
    echo "========================================="
    echo -e "${GREEN}Setup Complete!${NC}"
    echo "========================================="
    echo ""
    echo "To start the application later, run:"
    echo "  streamlit run Welcome.py"
    echo ""
    echo "For detailed documentation, see SETUP_GUIDE.md"
    echo ""
fi
