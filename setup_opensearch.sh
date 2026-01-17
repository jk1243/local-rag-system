#!/bin/bash
# Setup script for OpenSearch and OpenSearch Dashboard

set -e

echo "========================================="
echo "OpenSearch Setup Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Check if containers already exist
if docker ps -a | grep -q opensearch; then
    echo -e "${YELLOW}Warning: OpenSearch container already exists${NC}"
    read -p "Do you want to remove and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing OpenSearch container..."
        docker stop opensearch 2>/dev/null || true
        docker rm opensearch 2>/dev/null || true
    else
        echo "Skipping OpenSearch container creation"
    fi
fi

if docker ps -a | grep -q opensearch-dashboards; then
    echo -e "${YELLOW}Warning: OpenSearch Dashboard container already exists${NC}"
    read -p "Do you want to remove and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing OpenSearch Dashboard container..."
        docker stop opensearch-dashboards 2>/dev/null || true
        docker rm opensearch-dashboards 2>/dev/null || true
    else
        echo "Skipping OpenSearch Dashboard container creation"
    fi
fi

echo ""
echo "Step 1: Pulling Docker images..."
echo "========================================="

# Pull OpenSearch image
if docker images | grep -q "opensearchproject/opensearch.*2.11.0"; then
    echo -e "${GREEN}✓ OpenSearch 2.11.0 image already exists${NC}"
else
    echo "Pulling OpenSearch 2.11.0 image..."
    docker pull opensearchproject/opensearch:2.11.0
fi

# Pull OpenSearch Dashboard image
if docker images | grep -q "opensearchproject/opensearch-dashboards.*2.11.0"; then
    echo -e "${GREEN}✓ OpenSearch Dashboard 2.11.0 image already exists${NC}"
else
    echo "Pulling OpenSearch Dashboard 2.11.0 image..."
    docker pull opensearchproject/opensearch-dashboards:2.11.0
fi

echo ""
echo "Step 2: Starting OpenSearch container..."
echo "========================================="

# Start OpenSearch container
if ! docker ps | grep -q opensearch; then
    docker run -d --name opensearch \
      -p 9200:9200 -p 9600:9600 \
      -e "discovery.type=single-node" \
      -e "DISABLE_SECURITY_PLUGIN=true" \
      opensearchproject/opensearch:2.11.0

    echo -e "${GREEN}✓ OpenSearch container started${NC}"
else
    echo -e "${GREEN}✓ OpenSearch container is already running${NC}"
fi

echo ""
echo "Step 3: Starting OpenSearch Dashboard container..."
echo "========================================="

# Wait a bit for OpenSearch to start
echo "Waiting for OpenSearch to initialize (10 seconds)..."
sleep 10

# Start OpenSearch Dashboard container
if ! docker ps | grep -q opensearch-dashboards; then
    docker run -d --name opensearch-dashboards \
      -p 5601:5601 \
      --link opensearch:opensearch \
      -e "OPENSEARCH_HOSTS=http://opensearch:9200" \
      -e "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" \
      opensearchproject/opensearch-dashboards:2.11.0

    echo -e "${GREEN}✓ OpenSearch Dashboard container started${NC}"
else
    echo -e "${GREEN}✓ OpenSearch Dashboard container is already running${NC}"
fi

echo ""
echo "Step 4: Verifying OpenSearch is running..."
echo "========================================="

# Wait for OpenSearch to be ready
echo "Waiting for OpenSearch to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:9200 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OpenSearch is ready!${NC}"
        break
    fi
    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}Error: OpenSearch did not start within expected time${NC}"
    echo "Check logs with: docker logs opensearch"
    exit 1
fi

echo ""
echo "========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================="
echo ""
echo "OpenSearch is running at: http://localhost:9200"
echo "OpenSearch Dashboard is running at: http://localhost:5601"
echo ""
echo "Next steps:"
echo "1. Run ./configure_hybrid_search.sh to set up hybrid search pipeline"
echo "2. Install Python dependencies: pip install -r requirements.txt"
echo "3. Start the application: streamlit run Welcome.py"
echo ""
echo "To view container logs:"
echo "  docker logs opensearch"
echo "  docker logs opensearch-dashboards"
echo ""
echo "To stop containers:"
echo "  docker stop opensearch opensearch-dashboards"
echo ""
