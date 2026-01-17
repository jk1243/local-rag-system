#!/bin/bash
# Script to configure hybrid search pipeline in OpenSearch

set -e

echo "========================================="
echo "Hybrid Search Pipeline Configuration"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if OpenSearch is running
if ! curl -s http://localhost:9200 > /dev/null 2>&1; then
    echo -e "${RED}Error: OpenSearch is not running at http://localhost:9200${NC}"
    echo "Please start OpenSearch first by running: ./setup_opensearch.sh"
    exit 1
fi

echo -e "${GREEN}✓ OpenSearch is running${NC}"
echo ""

# Check if pipeline already exists
echo "Checking if hybrid search pipeline already exists..."
if curl -s http://localhost:9200/_search/pipeline/nlp-search-pipeline | grep -q "nlp-search-pipeline"; then
    echo -e "${YELLOW}Warning: Pipeline 'nlp-search-pipeline' already exists${NC}"
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping pipeline configuration"
        exit 0
    fi
fi

echo "Creating hybrid search pipeline..."
echo ""

# Create the hybrid search pipeline
response=$(curl -s -w "\n%{http_code}" -XPUT "http://localhost:9200/_search/pipeline/nlp-search-pipeline" \
  -H 'Content-Type: application/json' \
  -d '{
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
}')

# Extract HTTP status code (last line)
http_code=$(echo "$response" | tail -n1)

# Extract response body (everything except last line)
body=$(echo "$response" | sed '$d')

echo "Response from OpenSearch:"
echo "$body"
echo ""

# Check if successful (200 or 201)
if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
    echo -e "${GREEN}✓ Hybrid search pipeline configured successfully!${NC}"
    echo ""
    echo "Pipeline Details:"
    echo "  Name: nlp-search-pipeline"
    echo "  Normalization: min_max"
    echo "  Combination: arithmetic_mean"
    echo "  Weights: [0.3 (BM25), 0.7 (Vector)]"
    echo ""
    echo "This pipeline combines:"
    echo "  • Traditional text search (BM25) with 30% weight"
    echo "  • Semantic vector search with 70% weight"
    echo ""
else
    echo -e "${RED}Error: Failed to create pipeline (HTTP $http_code)${NC}"
    echo "Response: $body"
    exit 1
fi

# Verify the pipeline was created
echo "Verifying pipeline configuration..."
verify_response=$(curl -s http://localhost:9200/_search/pipeline/nlp-search-pipeline)

if echo "$verify_response" | grep -q "nlp-search-pipeline"; then
    echo -e "${GREEN}✓ Pipeline verified successfully${NC}"
    echo ""
    echo "Full pipeline configuration:"
    echo "$verify_response" | python3 -m json.tool 2>/dev/null || echo "$verify_response"
else
    echo -e "${YELLOW}Warning: Could not verify pipeline${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Configuration Complete!${NC}"
echo "========================================="
echo ""
echo "You can now use hybrid search in your RAG application."
echo ""
echo "To view the pipeline in OpenSearch Dashboard:"
echo "  1. Open http://localhost:5601"
echo "  2. Go to Dev Tools"
echo "  3. Run: GET /_search/pipeline/nlp-search-pipeline"
echo ""
