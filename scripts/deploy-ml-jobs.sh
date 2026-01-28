#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - ML Jobs Deployment"
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

# 1. Deploy ML Jobs
echo "Step 1: Deploying ML Jobs..."
ml_jobs_deployed=0
for job_file in elasticsearch/ml-jobs/*.json; do
    if [ -f "$job_file" ]; then
        # Read the job configuration
        job_config=$(cat "$job_file")
        job_id=$(echo "$job_config" | grep -o '"job_id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        # Extract datafeed config
        datafeed_config=$(echo "$job_config" | jq '.datafeed_config')
        job_only=$(echo "$job_config" | jq 'del(.datafeed_config)')
        
        echo -n "  - Creating ML job: $job_id... "
        response=$(es_api PUT "/_ml/anomaly_detectors/${job_id}" "$job_only")
        if echo "$response" | grep -q '"job_id":\|"acknowledged":true'; then
            echo -e "${GREEN}✓${NC}"
            ((ml_jobs_deployed++))
            
            # Create datafeed if configuration exists
            if [ "$datafeed_config" != "null" ]; then
                datafeed_id=$(echo "$datafeed_config" | jq -r '.datafeed_id')
                echo -n "    - Creating datafeed: $datafeed_id... "
                
                # Add job_id to datafeed config
                datafeed_with_job=$(echo "$datafeed_config" | jq ". + {\"job_id\": \"${job_id}\"}")
                
                response=$(es_api PUT "/_ml/datafeeds/${datafeed_id}" "$datafeed_with_job")
                if echo "$response" | grep -q '"datafeed_id":\|"acknowledged":true'; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${YELLOW}⚠${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠ (may already exist)${NC}"
        fi
    fi
done

# 2. Open ML Jobs
echo -e "\nStep 2: Opening ML Jobs..."
for job_file in elasticsearch/ml-jobs/*.json; do
    if [ -f "$job_file" ]; then
        job_config=$(cat "$job_file")
        job_id=$(echo "$job_config" | grep -o '"job_id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        echo -n "  - Opening job: $job_id... "
        response=$(es_api POST "/_ml/anomaly_detectors/${job_id}/_open" "")
        if echo "$response" | grep -q '"opened":true\|"task"'; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠ (may already be open)${NC}"
        fi
    fi
done

# 3. Start Datafeeds
echo -e "\nStep 3: Starting Datafeeds..."
for job_file in elasticsearch/ml-jobs/*.json; do
    if [ -f "$job_file" ]; then
        job_config=$(cat "$job_file")
        datafeed_config=$(echo "$job_config" | jq '.datafeed_config')
        
        if [ "$datafeed_config" != "null" ]; then
            datafeed_id=$(echo "$datafeed_config" | jq -r '.datafeed_id')
            
            echo -n "  - Starting datafeed: $datafeed_id... "
            response=$(es_api POST "/_ml/datafeeds/${datafeed_id}/_start" '{"start":"now-30d"}')
            if echo "$response" | grep -q '"started":true'; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${YELLOW}⚠ (may already be running)${NC}"
            fi
        fi
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ ML jobs deployment completed!${NC}"
echo -e "${GREEN}  Jobs deployed: $ml_jobs_deployed${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Check ML job status:"
echo "  curl -X GET \"${ES_URL}/_ml/anomaly_detectors/_stats\" \\"
echo "    -H \"Authorization: ApiKey \${ES_API_KEY}\""
echo ""
