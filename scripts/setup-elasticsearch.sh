#!/bin/bash

# Setup Elasticsearch configurations for NiFi Observability Platform
# This script creates index templates, ILM policies, and ingest pipelines

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
    echo "Please copy config/elasticsearch-cloud.yaml.example to config/elasticsearch-cloud.yaml and configure it."
    exit 1
fi

# Parse YAML config (requires yq or python)
if command -v yq &> /dev/null; then
    ES_HOST=$(yq eval '.elasticsearch.host' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
elif command -v python3 &> /dev/null; then
    ES_HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['host'])")
    ES_API_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['api_key'])")
else
    echo -e "${RED}❌ Neither yq nor python3 found. Please install one to parse YAML config.${NC}"
    exit 1
fi

# Validate configuration
if [ "$ES_HOST" == "https://your-elasticsearch-cloud.es.io:9243" ] || [ -z "$ES_HOST" ]; then
    echo -e "${RED}❌ Elasticsearch host not configured. Please update $CONFIG_FILE${NC}"
    exit 1
fi

echo "========================================="
echo "  NiFi Elasticsearch Setup"
echo "========================================="
echo "Elasticsearch Host: $ES_HOST"
echo ""

# Function to make API calls to Elasticsearch
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

# Test connection
echo "Testing Elasticsearch connection..."
if es_api "GET" "" | grep -q "version"; then
    echo -e "${GREEN}✅ Connected to Elasticsearch${NC}"
else
    echo -e "${RED}❌ Failed to connect to Elasticsearch${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo "  Creating ILM Policies"
echo "========================================="

# Create ILM policies
for ilm_file in "$PROJECT_ROOT"/elasticsearch/ilm-policies/*.json; do
    policy_name=$(basename "$ilm_file" .json)
    echo -n "Creating ILM policy: $policy_name... "
    
    response=$(es_api "PUT" "_ilm/policy/$policy_name" "$ilm_file")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        echo "Response: $response"
    fi
done

echo ""
echo "========================================="
echo "  Creating Ingest Pipelines"
echo "========================================="

# Create ingest pipelines
for pipeline_file in "$PROJECT_ROOT"/elasticsearch/ingest-pipelines/*.json; do
    pipeline_name=$(basename "$pipeline_file" .json)
    echo -n "Creating pipeline: $pipeline_name... "
    
    response=$(es_api "PUT" "_ingest/pipeline/$pipeline_name" "$pipeline_file")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        echo "Response: $response"
    fi
done

echo ""
echo "========================================="
echo "  Creating Index Templates"
echo "========================================="

# Create index templates
for template_file in "$PROJECT_ROOT"/elasticsearch/templates/*.json; do
    template_name=$(basename "$template_file" -template.json)
    echo -n "Creating template: $template_name... "
    
    response=$(es_api "PUT" "_index_template/$template_name" "$template_file")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        echo "Response: $response"
    fi
done

echo ""
echo "========================================="
echo "  Creating Initial Indices"
echo "========================================="

# Create initial indices with aliases
declare -a indices=("nifi-bulletins" "nifi-system-diagnostics" "nifi-flow-performance")

for index_name in "${indices[@]}"; do
    echo -n "Creating index: ${index_name}-000001... "
    
    # Create index with alias
    response=$(curl -s -X PUT "$ES_HOST/${index_name}-000001" \
        -H "Authorization: ApiKey $ES_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"aliases\": {
                \"$index_name\": {
                    \"is_write_index\": true
                }
            }
        }")
    
    if echo "$response" | grep -q "acknowledged"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  (may already exist)${NC}"
    fi
done

echo ""
echo "========================================="
echo "  Verification"
echo "========================================="

# Verify ILM policies
echo "ILM Policies:"
es_api "GET" "_ilm/policy" | python3 -m json.tool 2>/dev/null | grep -E "nifi-" || echo "  (using basic parsing)"

# Verify templates
echo ""
echo "Index Templates:"
es_api "GET" "_index_template/nifi-*" | python3 -m json.tool 2>/dev/null | grep -E "\"name\"" || echo "  (using basic parsing)"

# Verify pipelines
echo ""
echo "Ingest Pipelines:"
es_api "GET" "_ingest/pipeline/nifi-*" | python3 -m json.tool 2>/dev/null | grep -E "nifi-" || echo "  (using basic parsing)"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/setup-kibana.sh to import dashboards"
echo "  2. Run ./scripts/deploy-ml-jobs.sh to create ML jobs"
echo "  3. Configure your NiFi instance to send data to Elasticsearch"
