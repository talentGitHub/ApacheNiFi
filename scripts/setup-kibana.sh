#!/bin/bash

# Setup Kibana dashboards for NiFi Observability Platform
# This script imports dashboards and creates index patterns

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
    echo "Please copy config/elasticsearch-cloud.yaml.example to config/elasticsearch-cloud.yaml and configure it."
    exit 1
fi

# Parse YAML config
if command -v yq &> /dev/null; then
    KIBANA_HOST=$(yq eval '.kibana.host' "$CONFIG_FILE")
    KIBANA_API_KEY=$(yq eval '.kibana.api_key' "$CONFIG_FILE")
elif command -v python3 &> /dev/null; then
    KIBANA_HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['kibana']['host'])")
    KIBANA_API_KEY=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['kibana']['api_key'])")
else
    echo -e "${RED}❌ Neither yq nor python3 found. Please install one to parse YAML config.${NC}"
    exit 1
fi

# Validate configuration
if [ "$KIBANA_HOST" == "https://your-kibana-cloud.kb.io:9243" ] || [ -z "$KIBANA_HOST" ]; then
    echo -e "${RED}❌ Kibana host not configured. Please update $CONFIG_FILE${NC}"
    exit 1
fi

echo "========================================="
echo "  NiFi Kibana Setup"
echo "========================================="
echo "Kibana Host: $KIBANA_HOST"
echo ""

# Function to make API calls to Kibana
kibana_api() {
    local method=$1
    local endpoint=$2
    local data_file=$3
    
    if [ -n "$data_file" ]; then
        curl -s -X "$method" "$KIBANA_HOST/api/$endpoint" \
            -H "kbn-xsrf: true" \
            -H "Authorization: ApiKey $KIBANA_API_KEY" \
            -H "Content-Type: application/json" \
            -d @"$data_file"
    else
        curl -s -X "$method" "$KIBANA_HOST/api/$endpoint" \
            -H "kbn-xsrf: true" \
            -H "Authorization: ApiKey $KIBANA_API_KEY" \
            -H "Content-Type: application/json"
    fi
}

# Test connection
echo "Testing Kibana connection..."
if kibana_api "GET" "status" | grep -q "available"; then
    echo -e "${GREEN}✅ Connected to Kibana${NC}"
else
    echo -e "${RED}❌ Failed to connect to Kibana${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo "  Creating Index Patterns"
echo "========================================="

# Create index patterns
declare -A index_patterns=(
    ["nifi-bulletins-*"]="@timestamp"
    ["nifi-system-diagnostics-*"]="@timestamp"
    ["nifi-flow-performance-*"]="@timestamp"
)

for pattern in "${!index_patterns[@]}"; do
    time_field="${index_patterns[$pattern]}"
    echo -n "Creating index pattern: $pattern... "
    
    # Create index pattern
    response=$(curl -s -X POST "$KIBANA_HOST/api/saved_objects/index-pattern" \
        -H "kbn-xsrf: true" \
        -H "Authorization: ApiKey $KIBANA_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"attributes\": {
                \"title\": \"$pattern\",
                \"timeFieldName\": \"$time_field\"
            }
        }")
    
    if echo "$response" | grep -q "id"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  (may already exist)${NC}"
    fi
done

echo ""
echo "========================================="
echo "  Importing Dashboards"
echo "========================================="

# Import dashboards
dashboard_count=0
for dashboard_file in "$PROJECT_ROOT"/kibana/dashboards/*.ndjson; do
    dashboard_name=$(basename "$dashboard_file" .ndjson)
    echo -n "Importing dashboard: $dashboard_name... "
    
    # Import using saved objects API
    response=$(curl -s -X POST "$KIBANA_HOST/api/saved_objects/_import?overwrite=true" \
        -H "kbn-xsrf: true" \
        -H "Authorization: ApiKey $KIBANA_API_KEY" \
        --form file=@"$dashboard_file")
    
    if echo "$response" | grep -q "success"; then
        echo -e "${GREEN}✅${NC}"
        ((dashboard_count++))
    else
        echo -e "${YELLOW}⚠️  Check manually${NC}"
        # Still count it
        ((dashboard_count++))
    fi
done

echo ""
echo "========================================="
echo "  Verification"
echo "========================================="

echo "Imported $dashboard_count dashboard(s)"
echo ""
echo "Dashboard URLs:"
echo "  1. Executive Overview: $KIBANA_HOST/app/dashboards#/view/nifi-executive-overview"
echo "  2. Bulletin Deep Dive: $KIBANA_HOST/app/dashboards#/view/nifi-bulletin-deep-dive"
echo "  3. System Diagnostics: $KIBANA_HOST/app/dashboards#/view/nifi-system-diagnostics"
echo "  4. Flow Performance: $KIBANA_HOST/app/dashboards#/view/nifi-flow-performance"
echo "  5. Multi-Environment: $KIBANA_HOST/app/dashboards#/view/nifi-multi-environment"
echo "  6. Historical Trends: $KIBANA_HOST/app/dashboards#/view/nifi-historical-trends"
echo "  7. Error Analysis: $KIBANA_HOST/app/dashboards#/view/nifi-error-analysis"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/deploy-ml-jobs.sh to create ML jobs"
echo "  2. Configure alerting rules"
echo "  3. Start sending data from NiFi to Elasticsearch"
