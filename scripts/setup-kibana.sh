#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - Kibana Setup"
echo "========================================"

# Load configuration
CONFIG_FILE="config/elasticsearch-cloud.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Parse config
if command -v yq &> /dev/null; then
    KIBANA_ENDPOINT=$(yq eval '.kibana.endpoint' "$CONFIG_FILE")
    ES_API_KEY=$(yq eval '.elasticsearch.api_key' "$CONFIG_FILE")
else
    echo -e "${YELLOW}⚠ yq not found. Using environment variables${NC}"
    if [ -z "$KIBANA_ENDPOINT" ] || [ -z "$ES_API_KEY" ]; then
        echo -e "${RED}✗ Required environment variables not set${NC}"
        exit 1
    fi
fi

echo -e "\n${YELLOW}Using Kibana endpoint: $KIBANA_ENDPOINT${NC}\n"

# Function to make Kibana API calls
kibana_api() {
    local method=$1
    local path=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "${KIBANA_ENDPOINT}${path}" \
            -H "Authorization: ApiKey ${ES_API_KEY}" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${KIBANA_ENDPOINT}${path}" \
            -H "Authorization: ApiKey ${ES_API_KEY}" \
            -H "kbn-xsrf: true"
    fi
}

# 1. Import Dashboards
echo "Step 1: Importing Kibana Dashboards..."
dashboard_count=0
for dashboard in kibana/dashboards/*.ndjson; do
    if [ -f "$dashboard" ]; then
        dashboard_name=$(basename "$dashboard" .ndjson)
        echo -n "  - Importing dashboard: $dashboard_name... "
        response=$(kibana_api POST "/api/saved_objects/_import?overwrite=true" "@${dashboard}")
        if echo "$response" | grep -q '"success":true\|"successCount"'; then
            echo -e "${GREEN}✓${NC}"
            ((dashboard_count++))
        else
            echo -e "${RED}✗${NC}"
            echo "    Response: $response"
        fi
    fi
done

if [ $dashboard_count -eq 0 ]; then
    echo -e "${YELLOW}⚠ No dashboard files found in kibana/dashboards/${NC}"
    echo "  Dashboard files will be created with placeholders"
fi

# 2. Create Index Patterns
echo -e "\nStep 2: Creating Index Patterns..."
index_patterns=("nifi-bulletins-*" "nifi-system-diagnostics-*" "nifi-flow-performance-*" "nifi-ml-features-hourly" "nifi-ml-error-patterns")
for pattern in "${index_patterns[@]}"; do
    echo -n "  - Creating index pattern: $pattern... "
    data=$(cat <<EOF
{
  "attributes": {
    "title": "${pattern}",
    "timeFieldName": "@timestamp"
  }
}
EOF
)
    response=$(kibana_api POST "/api/saved_objects/index-pattern" "$data")
    if echo "$response" | grep -q '"id":'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (may already exist)${NC}"
    fi
done

# 3. Create Data Views (Kibana 8.x)
echo -e "\nStep 3: Creating Data Views..."
for pattern in "${index_patterns[@]}"; do
    echo -n "  - Creating data view: $pattern... "
    data=$(cat <<EOF
{
  "data_view": {
    "title": "${pattern}",
    "timeFieldName": "@timestamp"
  }
}
EOF
)
    response=$(kibana_api POST "/api/data_views/data_view" "$data")
    if echo "$response" | grep -q '"id":'; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (may already exist)${NC}"
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Kibana setup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access your dashboards at:"
echo "  ${KIBANA_ENDPOINT}/app/dashboards"
echo ""
echo "Available index patterns:"
for pattern in "${index_patterns[@]}"; do
    echo "  - $pattern"
done
echo ""
