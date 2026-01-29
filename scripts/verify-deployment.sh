#!/bin/bash

# Comprehensive verification script for NiFi Observability Platform
# Checks all components and reports status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/elasticsearch-cloud.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

check_component() {
    local name=$1
    local command=$2
    ((TOTAL_CHECKS++))
    
    echo -n "  Checking $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${RED}❌${NC}"
        ((FAILED_CHECKS++))
        return 1
    fi
}

check_component_warn() {
    local name=$1
    local command=$2
    ((TOTAL_CHECKS++))
    
    echo -n "  Checking $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${YELLOW}⚠️  (optional)${NC}"
        ((WARNING_CHECKS++))
        return 1
    fi
}

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    echo "Please copy config/elasticsearch-cloud.yaml.example and configure it."
    exit 1
fi

# Parse config
if command -v yq &> /dev/null; then
    ES_HOST=$(yq eval '.elasticsearch.host' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
    KIBANA_HOST=$(yq eval '.kibana.host' "$CONFIG_FILE")
elif command -v python3 &> /dev/null; then
    ES_HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['host'])" 2>/dev/null || echo "")
    ES_API_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['elasticsearch']['api_key'])" 2>/dev/null || echo "")
    KIBANA_HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['kibana']['host'])" 2>/dev/null || echo "")
else
    echo -e "${RED}❌ Neither yq nor python3 found${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo "  NiFi Observability Platform"
echo "  Deployment Verification"
echo "========================================="
echo ""

# 1. Elasticsearch Components
echo -e "${BLUE}[1/7] Elasticsearch Components${NC}"
check_component "Elasticsearch connection" "curl -s -X GET '$ES_HOST' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q version"
check_component "ILM policy: nifi-bulletins" "curl -s -X GET '$ES_HOST/_ilm/policy/nifi-bulletins-ilm-policy' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q policy"
check_component "ILM policy: nifi-system-diagnostics" "curl -s -X GET '$ES_HOST/_ilm/policy/nifi-system-diagnostics-ilm-policy' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q policy"
check_component "ILM policy: nifi-flow-performance" "curl -s -X GET '$ES_HOST/_ilm/policy/nifi-flow-performance-ilm-policy' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q policy"
check_component "Pipeline: nifi-bulletins" "curl -s -X GET '$ES_HOST/_ingest/pipeline/nifi-bulletins-pipeline' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q processors"
check_component "Pipeline: nifi-system-diagnostics" "curl -s -X GET '$ES_HOST/_ingest/pipeline/nifi-system-diagnostics-pipeline' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q processors"
check_component "Pipeline: nifi-flow-performance" "curl -s -X GET '$ES_HOST/_ingest/pipeline/nifi-flow-performance-pipeline' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q processors"
check_component "Template: nifi-bulletins" "curl -s -X GET '$ES_HOST/_index_template/nifi-bulletins' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q index_patterns"
check_component "Template: nifi-system-diagnostics" "curl -s -X GET '$ES_HOST/_index_template/nifi-system-diagnostics' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q index_patterns"
check_component "Template: nifi-flow-performance" "curl -s -X GET '$ES_HOST/_index_template/nifi-flow-performance' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q index_patterns"
echo ""

# 2. Kibana Dashboards
echo -e "${BLUE}[2/7] Kibana Dashboards${NC}"
check_component "Kibana connection" "curl -s -X GET '$KIBANA_HOST/api/status' -H 'kbn-xsrf: true' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q available"
check_component_warn "Dashboard: Executive Overview" "curl -s -X GET '$KIBANA_HOST/api/saved_objects/dashboard/nifi-executive-overview' -H 'kbn-xsrf: true' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
check_component_warn "Dashboard: Bulletin Deep Dive" "curl -s -X GET '$KIBANA_HOST/api/saved_objects/dashboard/nifi-bulletin-deep-dive' -H 'kbn-xsrf: true' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
check_component_warn "Dashboard: System Diagnostics" "curl -s -X GET '$KIBANA_HOST/api/saved_objects/dashboard/nifi-system-diagnostics' -H 'kbn-xsrf: true' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
check_component_warn "Dashboard: Flow Performance" "curl -s -X GET '$KIBANA_HOST/api/saved_objects/dashboard/nifi-flow-performance' -H 'kbn-xsrf: true' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
echo ""

# 3. ML Jobs
echo -e "${BLUE}[3/7] Machine Learning Jobs${NC}"
check_component_warn "ML job: nifi-processing-anomaly" "curl -s -X GET '$ES_HOST/_ml/anomaly_detectors/nifi-processing-anomaly' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q job_id"
check_component_warn "ML job: nifi-queue-forecast" "curl -s -X GET '$ES_HOST/_ml/anomaly_detectors/nifi-queue-forecast' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q job_id"
check_component_warn "ML job: nifi-error-spike" "curl -s -X GET '$ES_HOST/_ml/anomaly_detectors/nifi-error-spike' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q job_id"
echo ""

# 4. Transforms
echo -e "${BLUE}[4/7] Data Transforms${NC}"
check_component_warn "Transform: hourly processor performance" "curl -s -X GET '$ES_HOST/_transform/nifi-hourly-processor-performance' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
check_component_warn "Transform: error pattern analysis" "curl -s -X GET '$ES_HOST/_transform/nifi-error-pattern-analysis' -H 'Authorization: ApiKey $ES_API_KEY' | grep -q id"
echo ""

# 5. LLM Service
echo -e "${BLUE}[5/7] LLM Analysis Service${NC}"
check_component_warn "LLM service health" "curl -s -X GET 'http://localhost:5000/health' | grep -q healthy"
echo ""

# 6. File Structure
echo -e "${BLUE}[6/7] Project Structure${NC}"
check_component "Config directory" "test -d '$PROJECT_ROOT/config'"
check_component "Elasticsearch templates" "test -d '$PROJECT_ROOT/elasticsearch/templates' && [ \$(ls -1 $PROJECT_ROOT/elasticsearch/templates/*.json 2>/dev/null | wc -l) -eq 3 ]"
check_component "ILM policies" "test -d '$PROJECT_ROOT/elasticsearch/ilm-policies' && [ \$(ls -1 $PROJECT_ROOT/elasticsearch/ilm-policies/*.json 2>/dev/null | wc -l) -eq 3 ]"
check_component "Ingest pipelines" "test -d '$PROJECT_ROOT/elasticsearch/ingest-pipelines' && [ \$(ls -1 $PROJECT_ROOT/elasticsearch/ingest-pipelines/*.json 2>/dev/null | wc -l) -eq 3 ]"
check_component "Kibana dashboards" "test -d '$PROJECT_ROOT/kibana/dashboards' && [ \$(ls -1 $PROJECT_ROOT/kibana/dashboards/*.ndjson 2>/dev/null | wc -l) -eq 7 ]"
check_component "ML jobs" "test -d '$PROJECT_ROOT/ml/jobs' && [ \$(ls -1 $PROJECT_ROOT/ml/jobs/*.json 2>/dev/null | wc -l) -eq 3 ]"
check_component "Transforms" "test -d '$PROJECT_ROOT/ml/transforms' && [ \$(ls -1 $PROJECT_ROOT/ml/transforms/*.json 2>/dev/null | wc -l) -eq 2 ]"
check_component "NiFi templates" "test -d '$PROJECT_ROOT/nifi-templates' && [ \$(ls -1 $PROJECT_ROOT/nifi-templates/*.xml 2>/dev/null | wc -l) -eq 3 ]"
check_component "Scripts" "test -d '$PROJECT_ROOT/scripts' && [ \$(ls -1 $PROJECT_ROOT/scripts/*.sh 2>/dev/null | wc -l) -ge 4 ]"
echo ""

# 7. Documentation
echo -e "${BLUE}[7/7] Documentation${NC}"
check_component "README.md" "test -f '$PROJECT_ROOT/README.md'"
check_component_warn "DEPLOYMENT-GUIDE.md" "test -f '$PROJECT_ROOT/docs/DEPLOYMENT-GUIDE.md'"
check_component_warn "ARCHITECTURE.md" "test -f '$PROJECT_ROOT/docs/ARCHITECTURE.md'"
echo ""

# Summary
echo "========================================="
echo "  Verification Summary"
echo "========================================="
echo -e "Total checks: ${TOTAL_CHECKS}"
echo -e "${GREEN}Passed: ${PASSED_CHECKS}${NC}"
echo -e "${YELLOW}Warnings: ${WARNING_CHECKS}${NC}"
echo -e "${RED}Failed: ${FAILED_CHECKS}${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ All critical components verified successfully!${NC}"
    exit 0
elif [ $FAILED_CHECKS -le 3 ]; then
    echo -e "${YELLOW}⚠️  Some components need attention${NC}"
    exit 0
else
    echo -e "${RED}❌ Multiple components failed verification${NC}"
    exit 1
fi
