#!/bin/bash
#
# Pre-Import Validation Script
# Checks prerequisites before importing the System Health Dashboard
#
# Usage: ./validate-setup.sh [KIBANA_URL] [ES_URL]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
KIBANA_URL="${1:-${KIBANA_URL}}"
ES_URL="${2:-${ES_URL}}"
INDEX_PATTERN="nifi-diag*"
REQUIRED_FIELDS=(
    "@timestamp"
    "site"
    "systemDiagnostics.aggregateSnapshot.usedHeapBytes"
    "systemDiagnostics.aggregateSnapshot.maxHeapBytes"
    "systemDiagnostics.aggregateSnapshot.processorLoadAverage"
    "systemDiagnostics.aggregateSnapshot.garbageCollection.collectionMillis"
)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  System Health Dashboard - Pre-Import Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Prompt for credentials if URLs not provided
if [ -z "$KIBANA_URL" ]; then
    read -p "Kibana URL: " KIBANA_URL
fi

if [ -z "$ES_URL" ]; then
    read -p "Elasticsearch URL: " ES_URL
fi

read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo
echo

# Validation results
PASSED=0
FAILED=0
WARNINGS=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}✗${NC} $message"
        ((FAILED++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        ((WARNINGS++))
    else
        echo -e "${BLUE}ℹ${NC} $message"
    fi
}

echo -e "${YELLOW}[1/5] Checking Elasticsearch connectivity...${NC}"
ES_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" "${ES_URL}")

if [ "$ES_RESPONSE" = "200" ]; then
    print_status "pass" "Elasticsearch is accessible"
else
    print_status "fail" "Cannot connect to Elasticsearch (HTTP $ES_RESPONSE)"
fi
echo

echo -e "${YELLOW}[2/5] Checking Kibana connectivity...${NC}"
KIBANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" "${KIBANA_URL}/api/status")

if [ "$KIBANA_RESPONSE" = "200" ]; then
    print_status "pass" "Kibana is accessible"
else
    print_status "fail" "Cannot connect to Kibana (HTTP $KIBANA_RESPONSE)"
fi
echo

echo -e "${YELLOW}[3/5] Checking for ${INDEX_PATTERN} indices...${NC}"
INDICES_RESPONSE=$(curl -s -u "${USERNAME}:${PASSWORD}" "${ES_URL}/_cat/indices/${INDEX_PATTERN}?format=json")

if [ -n "$INDICES_RESPONSE" ] && [ "$INDICES_RESPONSE" != "[]" ]; then
    INDEX_COUNT=$(echo "$INDICES_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    print_status "pass" "Found $INDEX_COUNT index(es) matching ${INDEX_PATTERN}"
    
    # Get document count
    DOC_COUNT=$(echo "$INDICES_RESPONSE" | python3 -c "import sys, json; print(sum(int(i.get('docs.count', 0)) for i in json.load(sys.stdin)))" 2>/dev/null || echo "0")
    print_status "info" "Total documents: $DOC_COUNT"
else
    print_status "fail" "No indices found matching ${INDEX_PATTERN}"
fi
echo

echo -e "${YELLOW}[4/5] Verifying required fields...${NC}"

# Get sample document
SAMPLE_DOC=$(curl -s -u "${USERNAME}:${PASSWORD}" "${ES_URL}/${INDEX_PATTERN}/_search?size=1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    hits = data.get('hits', {}).get('hits', [])
    if hits:
        print(json.dumps(hits[0]['_source']))
    else:
        print('{}')
except:
    print('{}')
" 2>/dev/null)

if [ "$SAMPLE_DOC" = "{}" ]; then
    print_status "fail" "No documents found to validate fields"
else
    # Check each required field
    for field in "${REQUIRED_FIELDS[@]}"; do
        # Convert field path to jq query
        jq_query=$(echo "$field" | sed 's/\././g')
        
        FIELD_EXISTS=$(echo "$SAMPLE_DOC" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = '$field'.split('.')
    value = data
    for key in path:
        value = value.get(key, None)
        if value is None:
            break
    print('yes' if value is not None else 'no')
except:
    print('no')
" 2>/dev/null)
        
        if [ "$FIELD_EXISTS" = "yes" ]; then
            print_status "pass" "Field exists: $field"
        else
            print_status "fail" "Field missing: $field"
        fi
    done
fi
echo

echo -e "${YELLOW}[5/5] Checking Kibana index pattern...${NC}"
INDEX_PATTERN_RESPONSE=$(curl -s -u "${USERNAME}:${PASSWORD}" \
    "${KIBANA_URL}/api/saved_objects/_find?type=index-pattern&search_fields=title&search=${INDEX_PATTERN}")

HAS_PATTERN=$(echo "$INDEX_PATTERN_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('yes' if data.get('total', 0) > 0 else 'no')
except:
    print('no')
" 2>/dev/null)

if [ "$HAS_PATTERN" = "yes" ]; then
    print_status "pass" "Index pattern '${INDEX_PATTERN}' exists in Kibana"
else
    print_status "warn" "Index pattern '${INDEX_PATTERN}' not found in Kibana"
    echo -e "       ${YELLOW}You'll need to create it before importing the dashboard${NC}"
fi
echo

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Validation Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "  ${GREEN}Passed${NC}: $PASSED"
echo -e "  ${YELLOW}Warnings${NC}: $WARNINGS"
echo -e "  ${RED}Failed${NC}: $FAILED"
echo

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! You're ready to import the dashboard.${NC}"
    echo
    echo "Next step:"
    echo "  ./import-dashboard.sh $KIBANA_URL"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with warnings.${NC}"
    echo
    echo "Please address the warnings before importing:"
    echo "  - Create the index pattern in Kibana if missing"
    echo
    echo "Then run:"
    echo "  ./import-dashboard.sh $KIBANA_URL"
    exit 0
else
    echo -e "${RED}✗ Validation failed. Please resolve the issues above.${NC}"
    echo
    echo "Common issues:"
    echo "  - Verify Elasticsearch and Kibana URLs"
    echo "  - Check credentials and permissions"
    echo "  - Ensure NiFi is sending data to Elasticsearch"
    echo "  - Verify index names match '${INDEX_PATTERN}'"
    exit 1
fi
