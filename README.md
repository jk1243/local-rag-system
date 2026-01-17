# 📝 Build Your Local RAG System with LLMs

Welcome to the **Local LLM-based Retrieval-Augmented Generation (RAG) System**! This repository provides the full code to build a private, offline RAG system for managing and querying personal documents locally using a combination of OpenSearch, Sentence Transformers, and Large Language Models (LLMs). Perfect for anyone seeking a privacy-friendly solution to manage documents without relying on cloud services.

![Demo Image](images/chatbot.png)

### 🌟 Key Features:
- **Privacy-Friendly Document Search:** Search through personal documents without uploading them to the cloud.
- **Hybrid Search with OpenSearch:** Uses both traditional text matching and semantic search.
- **Easy Integration with LLMs**: Leverage local LLMs for personalized, context-aware responses.

### 🚀 Get Started

#### Quick Start (Automated)
Run the interactive setup script:
```bash
./quickstart.sh
```

#### Manual Setup
1. **Prerequisites**: Install [Docker](https://docs.docker.com/get-docker/), [Ollama](https://ollama.ai/download), and Python 3.11
2. **OpenSearch**: Run `./setup_opensearch.sh` to start OpenSearch and Dashboard
3. **Hybrid Search**: Run `./configure_hybrid_search.sh` to configure the search pipeline
4. **Dependencies**: Install Python packages with `pip install -r requirements.txt`
5. **LLM Model**: Pull an Ollama model: `ollama pull llama3.2:1b`
6. **Launch**: Start the app with `streamlit run Welcome.py`

📖 For detailed instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

### 📘 Blog Guide
For a detailed walkthrough of the setup and code, check out our blog:

[**Build a Local LLM-based RAG System for Your Personal Documents - Part 1**](https://jamwithai.substack.com/p/build-a-local-llm-based-rag-system)

[**Build a Local LLM-based RAG System for Your Personal Documents - Part 2: The Guide**](https://jamwithai.substack.com/p/build-a-local-llm-based-rag-system-628)

---

Enjoy your journey in building a private, AI-driven document management system! If you find this project useful, consider sharing it with others in the community!
