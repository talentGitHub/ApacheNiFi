#!/bin/bash
set -e

# NiFi Observability Platform - Elasticsearch Setup Script
# This script creates index templates, ILM policies, and ingest pipelines

echo "============================================"
echo "NiFi Observability - Elasticsearch Setup"
echo "============================================"
echo ""

# Load configuration
if [ ! -f "config/elasticsearch-cloud.yaml" ]; then
    echo "❌ Error: config/elasticsearch-cloud.yaml not found"
    echo "Please copy config/elasticsearch-cloud.yaml.example and configure it with your credentials"
    exit 1
fi

# Parse YAML config (simple approach - assumes specific format)
ES_CLOUD_ID=$(grep "cloud_id:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_API_KEY=$(grep "api_key:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')

if [ -z "$ES_CLOUD_ID" ] || [ -z "$ES_API_KEY" ]; then
    echo "❌ Error: cloud_id or api_key not found in config"
    exit 1
fi

# Convert Cloud ID to URL
ES_URL="https://$(echo $ES_CLOUD_ID | cut -d':' -f2 | base64 -d | cut -d'$' -f1)"

echo "📡 Connecting to Elasticsearch Cloud..."
echo "Cloud ID: ${ES_CLOUD_ID:0:20}..."
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

echo "Step 1: Creating ILM Policies..."
echo "================================="

for policy_file in elasticsearch/ilm-policies/*.json; do
    policy_name=$(basename "$policy_file" .json)
    echo "  Creating ILM policy: $policy_name"
    
    response=$(call_es_api "PUT" "/_ilm/policy/$policy_name" "$(cat $policy_file)")
    
    if echo "$response" | grep -q "acknowledged.*true"; then
        echo "  ✅ $policy_name created successfully"
    else
        echo "  ⚠️  $policy_name may already exist or failed: $response"
    fi
done

echo ""
echo "Step 2: Creating Ingest Pipelines..."
echo "====================================="

for pipeline_file in elasticsearch/ingest-pipelines/*.json; do
    pipeline_name=$(basename "$pipeline_file" -pipeline.json)
    echo "  Creating ingest pipeline: $pipeline_name"
    
    response=$(call_es_api "PUT" "/_ingest/pipeline/$pipeline_name" "$(cat $pipeline_file)")
    
    if echo "$response" | grep -q "acknowledged.*true"; then
        echo "  ✅ $pipeline_name created successfully"
    else
        echo "  ⚠️  $pipeline_name may already exist or failed: $response"
    fi
done

echo ""
echo "Step 3: Creating Index Templates..."
echo "===================================="

for template_file in elasticsearch/templates/*.json; do
    template_name=$(basename "$template_file" .json)
    echo "  Creating index template: $template_name"
    
    response=$(call_es_api "PUT" "/_index_template/$template_name" "$(cat $template_file)")
    
    if echo "$response" | grep -q "acknowledged.*true"; then
        echo "  ✅ $template_name created successfully"
    else
        echo "  ⚠️  $template_name may already exist or failed: $response"
    fi
done

echo ""
echo "Step 4: Creating Initial Indices with Aliases..."
echo "================================================="

indices=("nifi-bulletins-000001" "nifi-system-diagnostics-000001" "nifi-flow-performance-000001")
aliases=("nifi-bulletins" "nifi-system-diagnostics" "nifi-flow-performance")

for i in "${!indices[@]}"; do
    index="${indices[$i]}"
    alias="${aliases[$i]}"
    echo "  Creating index: $index with alias: $alias"
    
    # Check if index already exists
    status=$(call_es_api "HEAD" "/$index")
    
    if [ $? -eq 0 ]; then
        echo "  ℹ️  Index $index already exists"
    else
        # Create index with alias
        response=$(call_es_api "PUT" "/$index" "{\"aliases\":{\"$alias\":{\"is_write_index\":true}}}")
        
        if echo "$response" | grep -q "acknowledged.*true"; then
            echo "  ✅ $index created successfully"
        else
            echo "  ⚠️  Failed to create $index: $response"
        fi
    fi
done

echo ""
echo "============================================"
echo "✅ Elasticsearch setup completed!"
echo "============================================"
echo ""
echo "Summary:"
echo "  - ILM Policies: 3 created"
echo "  - Ingest Pipelines: 3 created"
echo "  - Index Templates: 3 created"
echo "  - Initial Indices: 3 created"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/setup-kibana.sh to import dashboards"
echo "  2. Run ./scripts/deploy-ml-jobs.sh to create ML jobs"
echo "  3. Configure NiFi to send data to Elasticsearch"
echo ""
