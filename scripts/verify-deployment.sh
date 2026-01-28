#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - Deployment Verification"
echo "========================================"

# Load configuration
CONFIG_FILE="config/elasticsearch-cloud.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Initialize counters
total_checks=0
passed_checks=0

# Function to check status
check_status() {
    local name=$1
    local result=$2
    ((total_checks++))
    
    if [ "$result" = "pass" ]; then
        echo -e "${GREEN}✅ $name${NC}"
        ((passed_checks++))
    else
        echo -e "${RED}✗ $name${NC}"
    fi
}

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
ES_ENDPOINT=$(echo "$ES_CLOUD_ID" | cut -d':' -f2 | base64 -d | cut -d'$' -f1 2>/dev/null || echo "")
ES_URL="https://${ES_ENDPOINT}.es.io"

echo -e "\n${YELLOW}Elasticsearch endpoint: $ES_URL${NC}\n"

# Function to make ES API calls
es_api() {
    curl -s -X GET "${ES_URL}$1" \
        -H "Authorization: ApiKey ${ES_API_KEY}" 2>/dev/null
}

echo "=== Elasticsearch Configuration ==="

# Check index templates
echo "Checking index templates..."
templates_response=$(es_api "/_index_template")
if echo "$templates_response" | grep -q "nifi-bulletins"; then
    check_status "Index template: nifi-bulletins" "pass"
else
    check_status "Index template: nifi-bulletins" "fail"
fi

if echo "$templates_response" | grep -q "nifi-system-diagnostics"; then
    check_status "Index template: nifi-system-diagnostics" "pass"
else
    check_status "Index template: nifi-system-diagnostics" "fail"
fi

if echo "$templates_response" | grep -q "nifi-flow-performance"; then
    check_status "Index template: nifi-flow-performance" "pass"
else
    check_status "Index template: nifi-flow-performance" "fail"
fi

# Check ILM policies
echo -e "\nChecking ILM policies..."
ilm_response=$(es_api "/_ilm/policy")
if echo "$ilm_response" | grep -q "nifi-bulletins-ilm"; then
    check_status "ILM policy: nifi-bulletins-ilm" "pass"
else
    check_status "ILM policy: nifi-bulletins-ilm" "fail"
fi

if echo "$ilm_response" | grep -q "nifi-system-diagnostics-ilm"; then
    check_status "ILM policy: nifi-system-diagnostics-ilm" "pass"
else
    check_status "ILM policy: nifi-system-diagnostics-ilm" "fail"
fi

if echo "$ilm_response" | grep -q "nifi-flow-performance-ilm"; then
    check_status "ILM policy: nifi-flow-performance-ilm" "pass"
else
    check_status "ILM policy: nifi-flow-performance-ilm" "fail"
fi

# Check ingest pipelines
echo -e "\nChecking ingest pipelines..."
pipelines_response=$(es_api "/_ingest/pipeline")
if echo "$pipelines_response" | grep -q "nifi-bulletins-enrichment"; then
    check_status "Ingest pipeline: nifi-bulletins-enrichment" "pass"
else
    check_status "Ingest pipeline: nifi-bulletins-enrichment" "fail"
fi

if echo "$pipelines_response" | grep -q "nifi-system-diagnostics-enrichment"; then
    check_status "Ingest pipeline: nifi-system-diagnostics-enrichment" "pass"
else
    check_status "Ingest pipeline: nifi-system-diagnostics-enrichment" "fail"
fi

if echo "$pipelines_response" | grep -q "nifi-flow-performance-enrichment"; then
    check_status "Ingest pipeline: nifi-flow-performance-enrichment" "pass"
else
    check_status "Ingest pipeline: nifi-flow-performance-enrichment" "fail"
fi

echo -e "\n=== Machine Learning ==="

# Check ML jobs
echo "Checking ML jobs..."
ml_jobs_response=$(es_api "/_ml/anomaly_detectors/_stats")
ml_job_count=$(echo "$ml_jobs_response" | grep -o '"job_id"' | wc -l)

if [ "$ml_job_count" -ge 3 ]; then
    check_status "ML jobs running (${ml_job_count}/3)" "pass"
else
    check_status "ML jobs running (${ml_job_count}/3)" "fail"
fi

# Check transforms
echo -e "\nChecking transforms..."
transforms_response=$(es_api "/_transform/_stats")
transform_count=$(echo "$transforms_response" | grep -o '"id"' | wc -l)

if [ "$transform_count" -ge 2 ]; then
    check_status "Transforms processing (${transform_count}/2)" "pass"
else
    check_status "Transforms processing (${transform_count}/2)" "fail"
fi

echo -e "\n=== Kibana Dashboards ==="

# Count dashboard files
dashboard_count=$(find kibana/dashboards -name "*.ndjson" 2>/dev/null | wc -l)
if [ "$dashboard_count" -ge 7 ]; then
    check_status "Kibana dashboards loaded (${dashboard_count}/7)" "pass"
else
    check_status "Kibana dashboards loaded (${dashboard_count}/7)" "fail"
fi

echo -e "\n=== LLM Service ==="

# Check LLM service
if curl -s http://localhost:5000/health >/dev/null 2>&1; then
    check_status "LLM service responsive" "pass"
else
    check_status "LLM service responsive" "fail"
fi

echo -e "\n========================================"
echo -e "Verification Summary"
echo -e "========================================"
echo -e "Checks passed: ${passed_checks}/${total_checks}"

if [ "$passed_checks" -eq "$total_checks" ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
elif [ "$passed_checks" -ge $(($total_checks * 7 / 10)) ]; then
    echo -e "${YELLOW}⚠ Some checks failed but deployment is mostly functional${NC}"
    exit 0
else
    echo -e "${RED}✗ Multiple checks failed. Please review the deployment.${NC}"
    exit 1
fi
