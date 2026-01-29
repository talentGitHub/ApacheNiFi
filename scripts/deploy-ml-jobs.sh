#!/bin/bash

# Deploy Machine Learning jobs for NiFi Observability Platform
# This script creates and starts ML anomaly detection jobs

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
echo "  NiFi ML Jobs Deployment"
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

echo "Creating ML jobs..."
echo ""

# Create ML jobs
job_count=0
for job_file in "$PROJECT_ROOT"/ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    echo -n "Creating ML job: $job_name... "
    
    # Extract job config and datafeed config
    job_config=$(python3 -c "
import json
with open('$job_file') as f:
    data = json.load(f)
    datafeed = data.pop('datafeed_config', None)
    print(json.dumps(data))
")
    
    datafeed_config=$(python3 -c "
import json
with open('$job_file') as f:
    data = json.load(f)
    datafeed = data.get('datafeed_config', {})
    datafeed['job_id'] = data['job_id']
    print(json.dumps(datafeed))
")
    
    # Create ML job
    response=$(echo "$job_config" | curl -s -X PUT "$ES_HOST/_ml/anomaly_detectors/$job_name" \
        -H "Authorization: ApiKey $ES_API_KEY" \
        -H "Content-Type: application/json" \
        -d @-)
    
    if echo "$response" | grep -q "job_id"; then
        echo -e "${GREEN}✅${NC}"
        
        # Create datafeed
        echo -n "  Creating datafeed... "
        datafeed_response=$(echo "$datafeed_config" | curl -s -X PUT "$ES_HOST/_ml/datafeeds/datafeed-$job_name" \
            -H "Authorization: ApiKey $ES_API_KEY" \
            -H "Content-Type: application/json" \
            -d @-)
        
        if echo "$datafeed_response" | grep -q "datafeed_id"; then
            echo -e "${GREEN}✅${NC}"
            ((job_count++))
        else
            echo -e "${YELLOW}⚠️${NC}"
        fi
    else
        echo -e "${RED}❌${NC}"
        echo "  Response: $response"
    fi
done

echo ""
echo "========================================="
echo "  Starting ML Jobs"
echo "========================================="

# Start ML jobs
for job_file in "$PROJECT_ROOT"/ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    echo -n "Opening ML job: $job_name... "
    
    response=$(es_api "POST" "_ml/anomaly_detectors/$job_name/_open")
    
    if echo "$response" | grep -q "opened"; then
        echo -e "${GREEN}✅${NC}"
        
        # Start datafeed
        echo -n "  Starting datafeed... "
        datafeed_response=$(es_api "POST" "_ml/datafeeds/datafeed-$job_name/_start")
        
        if echo "$datafeed_response" | grep -q "started"; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${YELLOW}⚠️  (may already be running)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  (may already be open)${NC}"
    fi
done

echo ""
echo "========================================="
echo "  Verification"
echo "========================================="

echo "ML Jobs Status:"
es_api "GET" "_ml/anomaly_detectors/_stats" | python3 -m json.tool 2>/dev/null | grep -A5 "job_id" || echo "  Check manually in Kibana ML"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Created $job_count ML job(s)"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/start-transforms.sh to start data transforms"
echo "  2. Monitor ML jobs in Kibana: $ES_HOST/app/ml"
echo "  3. Wait for ML models to train (may take 1-2 hours)"
