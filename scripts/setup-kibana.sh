#!/bin/bash
set -e

# NiFi Observability Platform - Kibana Setup Script
# This script imports dashboards into Kibana

echo "=========================================="
echo "NiFi Observability - Kibana Setup"
echo "=========================================="
echo ""

# Load configuration
if [ ! -f "config/elasticsearch-cloud.yaml" ]; then
    echo "❌ Error: config/elasticsearch-cloud.yaml not found"
    exit 1
fi

# Parse YAML config
ES_CLOUD_ID=$(grep "cloud_id:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
ES_API_KEY=$(grep "api_key:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')
KIBANA_URL=$(grep "kibana_url:" config/elasticsearch-cloud.yaml | cut -d':' -f2- | tr -d ' "')

if [ -z "$KIBANA_URL" ]; then
    # Construct Kibana URL from Cloud ID if not provided
    KIBANA_URL="https://$(echo $ES_CLOUD_ID | cut -d':' -f2 | base64 -d | cut -d'$' -f2)"
fi

echo "📊 Connecting to Kibana..."
echo "Kibana URL: ${KIBANA_URL:0:30}..."
echo ""

# Function to import dashboard
import_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .ndjson)
    
    echo "  Importing: $dashboard_name"
    
    response=$(curl -s -X POST \
        "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
        -H "Authorization: ApiKey ${ES_API_KEY}" \
        -H "kbn-xsrf: true" \
        --form file=@"$dashboard_file")
    
    if echo "$response" | grep -q "success.*true"; then
        echo "  ✅ $dashboard_name imported successfully"
        return 0
    else
        echo "  ⚠️  $dashboard_name import had issues: $response"
        return 1
    fi
}

echo "Step 1: Creating Index Patterns..."
echo "==================================="

# Create index patterns
index_patterns=("nifi-bulletins-*" "nifi-system-diagnostics-*" "nifi-flow-performance-*")

for pattern in "${index_patterns[@]}"; do
    echo "  Creating index pattern: $pattern"
    
    # Index patterns are typically created automatically when data arrives
    # or can be created via Kibana UI
    echo "  ℹ️  Index pattern $pattern will be auto-created when dashboards are imported"
done

echo ""
echo "Step 2: Importing Dashboards..."
echo "================================"

success_count=0
total_count=0

for dashboard_file in kibana/dashboards/*.ndjson; do
    total_count=$((total_count + 1))
    if import_dashboard "$dashboard_file"; then
        success_count=$((success_count + 1))
    fi
    echo ""
done

echo "=========================================="
echo "✅ Kibana setup completed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Dashboards imported: $success_count/$total_count"
echo ""
echo "Available Dashboards:"
echo "  1. Executive Overview: ${KIBANA_URL}/app/dashboards#/view/nifi-executive-overview"
echo "  2. Bulletin Deep Dive: ${KIBANA_URL}/app/dashboards#/view/nifi-bulletin-deep-dive"
echo "  3. System Diagnostics: ${KIBANA_URL}/app/dashboards#/view/nifi-system-diagnostics-health"
echo "  4. Flow Performance: ${KIBANA_URL}/app/dashboards#/view/nifi-flow-performance-analytics"
echo "  5. Multi-Environment: ${KIBANA_URL}/app/dashboards#/view/nifi-multi-environment-overview"
echo "  6. Historical Trends: ${KIBANA_URL}/app/dashboards#/view/nifi-historical-trends-capacity"
echo "  7. Error Analysis: ${KIBANA_URL}/app/dashboards#/view/nifi-specific-error-analysis"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/deploy-ml-jobs.sh to deploy ML jobs"
echo "  2. Run ./scripts/start-transforms.sh to start transforms"
echo "  3. Configure alerting rules in Kibana UI"
echo ""
