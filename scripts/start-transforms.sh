#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - Start Transforms"
echo "========================================"

# Load configuration
CONFIG_FILE="config/elasticsearch-cloud.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Parse config
if command -v yq &> /dev/null; then
    ES_CLOUD_ID=$(yq eval '.elasticsearch.cloud_id' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
else
    echo -e "${YELLOW}⚠ yq not found. Using environment variables${NC}"
    if [ -z "$ES_CLOUD_ID" ] || [ -z "$ES_API_KEY" ]; then
        echo -e "${RED}✗ Required environment variables not set${NC}"
        exit 1
    fi
fi

# Extract Elasticsearch endpoint
ES_ENDPOINT=$(echo "$ES_CLOUD_ID" | cut -d':' -f2 | base64 -d | cut -d'$' -f1)
ES_URL="https://${ES_ENDPOINT}.es.io"

echo -e "\n${YELLOW}Using Elasticsearch endpoint: $ES_URL${NC}\n"

# Function to make ES API calls
es_api() {
    local method=$1
    local path=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "${ES_URL}${path}" \
            -H "Authorization: ApiKey ${ES_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${ES_URL}${path}" \
            -H "Authorization: ApiKey ${ES_API_KEY}"
    fi
}

# 1. Create Transforms
echo "Step 1: Creating Transforms..."
transforms_created=0
for transform_file in elasticsearch/transforms/*.json; do
    if [ -f "$transform_file" ]; then
        transform_config=$(cat "$transform_file")
        transform_id=$(echo "$transform_config" | grep -o '"transform_id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        echo -n "  - Creating transform: $transform_id... "
        response=$(es_api PUT "/_transform/${transform_id}" "$transform_config")
        if echo "$response" | grep -q '"acknowledged":true\|"transform"'; then
            echo -e "${GREEN}✓${NC}"
            ((transforms_created++))
        else
            echo -e "${YELLOW}⚠ (may already exist)${NC}"
        fi
    fi
done

# 2. Start Transforms
echo -e "\nStep 2: Starting Transforms..."
for transform_file in elasticsearch/transforms/*.json; do
    if [ -f "$transform_file" ]; then
        transform_config=$(cat "$transform_file")
        transform_id=$(echo "$transform_config" | grep -o '"transform_id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        echo -n "  - Starting transform: $transform_id... "
        response=$(es_api POST "/_transform/${transform_id}/_start" "")
        if echo "$response" | grep -q '"acknowledged":true'; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠ (may already be running)${NC}"
        fi
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Transforms started!${NC}"
echo -e "${GREEN}  Transforms created: $transforms_created${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Check transform status:"
echo "  curl -X GET \"${ES_URL}/_transform/_stats\" \\"
echo "    -H \"Authorization: ApiKey \${ES_API_KEY}\""
echo ""
