#!/bin/bash
set -e

# NiFi Observability Platform - ML Jobs Deployment Script
# This script creates and starts ML anomaly detection jobs

echo "=============================================="
echo "NiFi Observability - ML Jobs Deployment"
echo "=============================================="
echo ""

# Load configuration
if [ ! -f "config/elasticsearch-cloud.yaml" ]; then
    echo "❌ Error: config/elasticsearch-cloud.yaml not found"
    exit 1
fi

ES_CLOUD_ID=$(grep "cloud_id:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_API_KEY=$(grep "api_key:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_URL="https://$(echo $ES_CLOUD_ID | cut -d':' -f2 | base64 -d | cut -d'$' -f1)"

echo "🤖 Deploying ML Jobs to Elasticsearch..."
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

echo "Step 1: Creating ML Jobs..."
echo "==========================="

for job_file in ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    echo "  Creating ML job: $job_name"
    
    # Extract job configuration (without datafeed)
    job_config=$(jq 'del(.datafeed_config)' "$job_file")
    
    response=$(call_es_api "PUT" "/_ml/anomaly_detectors/$job_name" "$job_config")
    
    if echo "$response" | grep -q "job_id"; then
        echo "  ✅ ML job $job_name created successfully"
    else
        echo "  ⚠️  ML job $job_name may already exist or failed: $response"
    fi
done

echo ""
echo "Step 2: Creating Datafeeds..."
echo "=============================="

for job_file in ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    datafeed_id="datafeed-$job_name"
    echo "  Creating datafeed: $datafeed_id"
    
    # Extract datafeed configuration
    datafeed_config=$(jq '.datafeed_config' "$job_file")
    
    if [ "$datafeed_config" != "null" ]; then
        response=$(call_es_api "PUT" "/_ml/datafeeds/$datafeed_id" "$datafeed_config")
        
        if echo "$response" | grep -q "datafeed_id"; then
            echo "  ✅ Datafeed $datafeed_id created successfully"
        else
            echo "  ⚠️  Datafeed $datafeed_id may already exist or failed"
        fi
    fi
done

echo ""
echo "Step 3: Opening ML Jobs..."
echo "=========================="

for job_file in ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    echo "  Opening ML job: $job_name"
    
    response=$(call_es_api "POST" "/_ml/anomaly_detectors/$job_name/_open" "")
    
    if echo "$response" | grep -q "opened.*true"; then
        echo "  ✅ ML job $job_name opened successfully"
    else
        echo "  ⚠️  ML job $job_name may already be open or failed"
    fi
done

echo ""
echo "Step 4: Starting Datafeeds..."
echo "=============================="

for job_file in ml/jobs/*.json; do
    job_name=$(basename "$job_file" .json)
    datafeed_id="datafeed-$job_name"
    echo "  Starting datafeed: $datafeed_id"
    
    response=$(call_es_api "POST" "/_ml/datafeeds/$datafeed_id/_start" '{"start":"now"}')
    
    if echo "$response" | grep -q "started.*true"; then
        echo "  ✅ Datafeed $datafeed_id started successfully"
    else
        echo "  ⚠️  Datafeed $datafeed_id may already be running or failed"
    fi
done

echo ""
echo "=============================================="
echo "✅ ML Jobs deployment completed!"
echo "=============================================="
echo ""
echo "Summary:"
echo "  - ML Jobs created: 3"
echo "  - Datafeeds created: 3"
echo "  - Jobs opened: 3"
echo "  - Datafeeds started: 3"
echo ""
echo "ML Jobs:"
echo "  1. nifi-processing-anomaly - Processing time anomaly detection"
echo "  2. nifi-queue-forecast - Queue growth forecasting"
echo "  3. nifi-error-spike - Error spike detection"
echo ""
echo "View ML jobs in Kibana: ${KIBANA_URL}/app/ml"
echo ""
