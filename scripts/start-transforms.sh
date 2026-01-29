#!/bin/bash

# Start Transform jobs for NiFi Observability Platform
# This script creates and starts continuous transforms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/elasticsearch-cloud.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Parse YAML config
if command -v yq &> /dev/null; then
    ES_HOST=$(yq eval '.elasticsearch.host' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
elif command -v python3 &> /dev/null; then
    ES_HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['host'])")
    ES_API_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['api_key'])")
else
    echo -e "${RED}❌ Neither yq nor python3 found.${NC}"
    exit 1
fi

echo "========================================="
echo "  NiFi Transforms Deployment"
echo "========================================="
echo "Elasticsearch Host: $ES_HOST"
echo ""

# Function to make API calls
es_api() {
    local method=$1
    local endpoint=$2
    local data_file=$3
    
    if [ -n "$data_file" ]; then
        curl -s -X "$method" "$ES_HOST/$endpoint" \
            -H "Authorization: ApiKey $ES_API_KEY" \
            -H "Content-Type: application/json" \
            -d @"$data_file"
    else
        curl -s -X "$method" "$ES_HOST/$endpoint" \
            -H "Authorization: ApiKey $ES_API_KEY" \
            -H "Content-Type: application/json"
    fi
}

echo "Creating transforms..."
echo ""

# Create transforms
transform_count=0
for transform_file in "$PROJECT_ROOT"/ml/transforms/*.json; do
    transform_name=$(basename "$transform_file" .json)
    echo -n "Creating transform: $transform_name... "
    
    response=$(es_api "PUT" "_transform/$transform_name" "$transform_file")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
        ((transform_count++))
    else
        echo -e "${YELLOW}⚠️  (may already exist)${NC}"
        ((transform_count++))
    fi
done

echo ""
echo "========================================="
echo "  Starting Transforms"
echo "========================================="

# Start transforms
for transform_file in "$PROJECT_ROOT"/ml/transforms/*.json; do
    transform_name=$(basename "$transform_file" .json)
    echo -n "Starting transform: $transform_name... "
    
    response=$(es_api "POST" "_transform/$transform_name/_start")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  (may already be running)${NC}"
    fi
done

echo ""
echo "========================================="
echo "  Verification"
echo "========================================="

echo "Transform Status:"
es_api "GET" "_transform/_stats" | python3 -m json.tool 2>/dev/null | grep -A5 "id" || echo "  Check manually in Kibana"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Started $transform_count transform(s)"
echo ""
echo "Next steps:"
echo "  1. Monitor transforms in Kibana: $ES_HOST/app/management/data/transform"
echo "  2. Verify data is being aggregated in destination indices"
echo "  3. Deploy LLM analysis service"
