#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - Elasticsearch Setup"
echo "========================================"

# Load configuration
CONFIG_FILE="config/elasticsearch-cloud.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    echo "  Please copy config/elasticsearch-cloud.yaml.example to config/elasticsearch-cloud.yaml"
    echo "  and fill in your Elasticsearch credentials."
    exit 1
fi

# Parse YAML config (simplified - requires yq or manual parsing)
if command -v yq &> /dev/null; then
    ES_CLOUD_ID=$(yq eval '.elasticsearch.cloud_id' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
else
    echo -e "${YELLOW}⚠ yq not found. Please install yq or set environment variables manually:${NC}"
    echo "  export ES_CLOUD_ID='your-cloud-id'"
    echo "  export ES_API_KEY='your-api-key'"
    if [ -z "$ES_CLOUD_ID" ] || [ -z "$ES_API_KEY" ]; then
        exit 1
    fi
fi

# Extract Elasticsearch endpoint from cloud_id
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

# 1. Create ILM Policies
echo "Step 1: Creating ILM Policies..."
for policy in elasticsearch/ilm-policies/*.json; do
    policy_name=$(basename "$policy" .json)
    echo -n "  - Creating policy: $policy_name... "
    response=$(es_api PUT "/_ilm/policy/${policy_name}" "@${policy}")
    if echo "$response" | grep -q '"acknowledged":true'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "    Response: $response"
    fi
done

# 2. Create Ingest Pipelines
echo -e "\nStep 2: Creating Ingest Pipelines..."
for pipeline in elasticsearch/ingest-pipelines/*.json; do
    pipeline_name=$(basename "$pipeline" .json)
    echo -n "  - Creating pipeline: $pipeline_name... "
    response=$(es_api PUT "/_ingest/pipeline/${pipeline_name}" "@${pipeline}")
    if echo "$response" | grep -q '"acknowledged":true'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "    Response: $response"
    fi
done

# 3. Create Index Templates
echo -e "\nStep 3: Creating Index Templates..."
for template in elasticsearch/index-templates/*.json; do
    template_name=$(basename "$template" .json)
    echo -n "  - Creating template: $template_name... "
    response=$(es_api PUT "/_index_template/${template_name}" "@${template}")
    if echo "$response" | grep -q '"acknowledged":true'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "    Response: $response"
    fi
done

# 4. Create initial indices
echo -e "\nStep 4: Creating initial indices..."
indices=("nifi-bulletins-000001" "nifi-system-diagnostics-000001" "nifi-flow-performance-000001")
for index in "${indices[@]}"; do
    echo -n "  - Creating index: $index... "
    
    # Extract the alias name
    alias_name=$(echo "$index" | sed 's/-[0-9]\{6\}$//')
    
    response=$(es_api PUT "/${index}" "{\"aliases\":{\"${alias_name}\":{\"is_write_index\":true}}}")
    if echo "$response" | grep -q '"acknowledged":true\|"index":"'${index}'"'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (may already exist)${NC}"
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Elasticsearch setup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/setup-kibana.sh to import dashboards"
echo "  2. Run ./scripts/deploy-ml-jobs.sh to deploy ML jobs"
echo "  3. Run ./scripts/start-transforms.sh to start transforms"
echo ""
