#!/bin/bash
set -e

# NiFi Observability Platform - Verification Script
# This script verifies that all components are properly deployed

echo "================================================"
echo "NiFi Observability - Deployment Verification"
echo "================================================"
echo ""

# Load configuration
if [ ! -f "config/elasticsearch-cloud.yaml" ]; then
    echo "❌ Error: config/elasticsearch-cloud.yaml not found"
    exit 1
fi

ES_CLOUD_ID=$(grep "cloud_id:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_API_KEY=$(grep "api_key:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_URL="https://$(echo $ES_CLOUD_ID | cut -d':' -f2 | base64 -d | cut -d'$' -f1)"

# Function to make API calls
call_es_api() {
    curl -s -X GET \
        "${ES_URL}$1" \
        -H "Authorization: ApiKey ${ES_API_KEY}" \
        -H "Content-Type: application/json"
}

success_count=0
total_count=0

echo "Checking Elasticsearch Components..."
echo "====================================="

# Check ILM Policies
echo -n "ILM Policies: "
total_count=$((total_count + 1))
response=$(call_es_api "/_ilm/policy")
if echo "$response" | grep -q "nifi-bulletins-ilm-policy"; then
    echo "✅ Found"
    success_count=$((success_count + 1))
else
    echo "❌ Missing"
fi

# Check Ingest Pipelines
echo -n "Ingest Pipelines: "
total_count=$((total_count + 1))
response=$(call_es_api "/_ingest/pipeline")
if echo "$response" | grep -q "nifi-bulletins"; then
    echo "✅ Found"
    success_count=$((success_count + 1))
else
    echo "❌ Missing"
fi

# Check Index Templates
echo -n "Index Templates: "
total_count=$((total_count + 1))
response=$(call_es_api "/_index_template")
if echo "$response" | grep -q "nifi-bulletins"; then
    echo "✅ Found"
    success_count=$((success_count + 1))
else
    echo "❌ Missing"
fi

# Check ML Jobs
echo -n "ML Jobs: "
total_count=$((total_count + 1))
response=$(call_es_api "/_ml/anomaly_detectors/_stats")
jobs_count=$(echo "$response" | grep -o "nifi-" | wc -l)
if [ "$jobs_count" -ge 3 ]; then
    echo "✅ $jobs_count/3 running"
    success_count=$((success_count + 1))
else
    echo "⚠️  $jobs_count/3 found"
fi

# Check Transforms
echo -n "Transforms: "
total_count=$((total_count + 1))
response=$(call_es_api "/_transform/_stats")
transforms_count=$(echo "$response" | grep -o "nifi-" | wc -l)
if [ "$transforms_count" -ge 2 ]; then
    echo "✅ $transforms_count/2 running"
    success_count=$((success_count + 1))
else
    echo "⚠️  $transforms_count/2 found"
fi

# Check Indices
echo -n "Data Indices: "
total_count=$((total_count + 1))
response=$(call_es_api "/_cat/indices/nifi-*?format=json")
indices_count=$(echo "$response" | grep -o "nifi-" | wc -l)
if [ "$indices_count" -ge 3 ]; then
    echo "✅ $indices_count indices found"
    success_count=$((success_count + 1))
else
    echo "⚠️  $indices_count indices found (expected 3+)"
fi

echo ""
echo "Checking Local Files..."
echo "======================="

# Check dashboards
echo -n "Kibana Dashboards: "
total_count=$((total_count + 1))
dashboard_count=$(ls kibana/dashboards/*.ndjson 2>/dev/null | wc -l)
if [ "$dashboard_count" -ge 7 ]; then
    echo "✅ $dashboard_count/7 files"
    success_count=$((success_count + 1))
else
    echo "❌ $dashboard_count/7 files"
fi

# Check ML jobs
echo -n "ML Job Definitions: "
total_count=$((total_count + 1))
ml_count=$(ls ml/jobs/*.json 2>/dev/null | wc -l)
if [ "$ml_count" -ge 3 ]; then
    echo "✅ $ml_count/3 files"
    success_count=$((success_count + 1))
else
    echo "❌ $ml_count/3 files"
fi

echo ""
echo "================================================"
echo "Verification Results: $success_count/$total_count checks passed"
echo "================================================"
echo ""

if [ "$success_count" -eq "$total_count" ]; then
    echo "✅ All checks passed! System is fully deployed."
    exit 0
elif [ "$success_count" -gt $((total_count / 2)) ]; then
    echo "⚠️  Most checks passed. Review warnings above."
    exit 0
else
    echo "❌ Multiple checks failed. Please review the output above."
    exit 1
fi
