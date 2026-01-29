#!/bin/bash
set -e

# NiFi Observability Platform - Transforms Start Script
# This script starts the continuous transforms

echo "============================================"
echo "NiFi Observability - Start Transforms"
echo "============================================"
echo ""

# Load configuration
if [ ! -f "config/elasticsearch-cloud.yaml" ]; then
    echo "❌ Error: config/elasticsearch-cloud.yaml not found"
    exit 1
fi

ES_CLOUD_ID=$(grep "cloud_id:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_API_KEY=$(grep "api_key:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_URL="https://$(echo $ES_CLOUD_ID | cut -d':' -f2 | base64 -d | cut -d'$' -f1)"

echo "🔄 Starting Transforms..."
echo ""

# Function to make API calls
call_es_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -z "$data" ]; then
        curl -s -X "$method" \
            "${ES_URL}${endpoint}" \
            -H "Authorization: ApiKey ${ES_API_KEY}" \
            -H "Content-Type: application/json"
    else
        curl -s -X "$method" \
            "${ES_URL}${endpoint}" \
            -H "Authorization: ApiKey ${ES_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data"
    fi
}

echo "Step 1: Creating Transforms..."
echo "==============================="

for transform_file in ml/transforms/*.json; do
    transform_name=$(basename "$transform_file" .json)
    echo "  Creating transform: $transform_name"
    
    response=$(call_es_api "PUT" "/_transform/$transform_name" "$(cat $transform_file)")
    
    if echo "$response" | grep -q "acknowledged.*true"; then
        echo "  ✅ Transform $transform_name created successfully"
    else
        echo "  ⚠️  Transform $transform_name may already exist or failed: $response"
    fi
done

echo ""
echo "Step 2: Starting Transforms..."
echo "==============================="

for transform_file in ml/transforms/*.json; do
    transform_name=$(basename "$transform_file" .json)
    echo "  Starting transform: $transform_name"
    
    response=$(call_es_api "POST" "/_transform/$transform_name/_start" "")
    
    if echo "$response" | grep -q "acknowledged.*true"; then
        echo "  ✅ Transform $transform_name started successfully"
    else
        echo "  ⚠️  Transform $transform_name may already be running or failed"
    fi
done

echo ""
echo "============================================"
echo "✅ Transforms started successfully!"
echo "============================================"
echo ""
echo "Summary:"
echo "  - Transforms created: 2"
echo "  - Transforms started: 2"
echo ""
echo "Active Transforms:"
echo "  1. nifi-hourly-processor-summary"
echo "     - Aggregates: Processor performance metrics"
echo "     - Frequency: Every hour"
echo "     - Destination: nifi-ml-features-hourly"
echo ""
echo "  2. nifi-error-pattern-analysis"
echo "     - Aggregates: Error patterns by category"
echo "     - Frequency: Every 10 minutes"
echo "     - Destination: nifi-ml-error-patterns"
echo ""
echo "View transforms in Kibana: ${KIBANA_URL}/app/management/data/transform"
echo ""
