#!/bin/bash

################################################################################
# Kibana Dashboard Setup Script
# 
# This script automates the import of NiFi monitoring dashboards into Kibana.
# It verifies connectivity, creates index patterns, and imports all dashboard
# configurations.
#
# Usage: ./scripts/setup-kibana.sh
# 
# Prerequisites:
# - Kibana 8.x running and accessible
# - curl and jq installed
# - API key or credentials for Kibana
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
KIBANA_DASHBOARDS_DIR="${PROJECT_ROOT}/kibana/dashboards"
KIBANA_INDEX_PATTERNS_DIR="${PROJECT_ROOT}/kibana/index-patterns"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

################################################################################
# Configuration Collection
################################################################################

collect_configuration() {
    print_header "Kibana Configuration"
    
    print_warning "Note: Credentials will be stored in memory during script execution"
    print_warning "For production use, consider setting KIBANA_URL and KIBANA_API_KEY as environment variables"
    echo ""
    
    # Kibana URL
    if [ -z "$KIBANA_URL" ]; then
        echo -n "Enter Kibana URL (e.g., https://your-deployment.kb.cloud.elastic.io): "
        read KIBANA_URL
    fi
    
    # Validate URL format
    if [[ ! "$KIBANA_URL" =~ ^https?:// ]]; then
        print_error "Invalid URL format. URL must start with http:// or https://"
        exit 1
    fi
    
    # Remove trailing slash if present
    KIBANA_URL="${KIBANA_URL%/}"
    
    # Authentication method
    echo ""
    echo "Select authentication method:"
    echo "1) API Key (recommended)"
    echo "2) Username/Password"
    echo -n "Choice [1-2]: "
    read AUTH_METHOD
    
    if [ "$AUTH_METHOD" = "1" ]; then
        if [ -z "$KIBANA_API_KEY" ]; then
            echo -n "Enter Kibana API Key: "
            read -s KIBANA_API_KEY
            echo ""
        fi
        AUTH_HEADER="Authorization: ApiKey ${KIBANA_API_KEY}"
    else
        if [ -z "$KIBANA_USERNAME" ]; then
            echo -n "Enter Kibana username: "
            read KIBANA_USERNAME
        fi
        if [ -z "$KIBANA_PASSWORD" ]; then
            echo -n "Enter Kibana password: "
            read -s KIBANA_PASSWORD
            echo ""
        fi
        AUTH_HEADER="Authorization: Basic $(echo -n "${KIBANA_USERNAME}:${KIBANA_PASSWORD}" | base64)"
    fi
    
    # Verify Elasticsearch URL (optional, for index verification)
    echo ""
    echo -n "Enter Elasticsearch URL (optional, press Enter to skip): "
    read ELASTICSEARCH_URL
    
    if [ -n "$ELASTICSEARCH_URL" ]; then
        # Validate URL format
        if [[ ! "$ELASTICSEARCH_URL" =~ ^https?:// ]]; then
            print_error "Invalid URL format. URL must start with http:// or https://"
            exit 1
        fi
        
        ELASTICSEARCH_URL="${ELASTICSEARCH_URL%/}"
        echo -n "Use same authentication for Elasticsearch? [Y/n]: "
        read ES_SAME_AUTH
        
        if [[ "$ES_SAME_AUTH" =~ ^[Nn] ]]; then
            echo -n "Enter Elasticsearch API Key: "
            read -s ES_API_KEY
            echo ""
            ES_AUTH_HEADER="Authorization: ApiKey ${ES_API_KEY}"
        else
            ES_AUTH_HEADER="$AUTH_HEADER"
        fi
    fi
    
    echo ""
    print_success "Configuration collected"
}

################################################################################
# Verification Functions
################################################################################

verify_kibana_connectivity() {
    print_header "Verifying Kibana Connectivity"
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "kbn-xsrf: true" \
        -H "$AUTH_HEADER" \
        "${KIBANA_URL}/api/status")
    
    if [ "$RESPONSE" = "200" ]; then
        print_success "Successfully connected to Kibana"
        return 0
    else
        print_error "Failed to connect to Kibana (HTTP ${RESPONSE})"
        print_warning "Please check your URL and credentials"
        exit 1
    fi
}

verify_required_indices() {
    print_header "Verifying Elasticsearch Indices"
    
    if [ -z "$ELASTICSEARCH_URL" ]; then
        print_warning "Elasticsearch URL not provided, skipping index verification"
        return 0
    fi
    
    REQUIRED_INDICES=("nifi-bulletins-*" "nifi-system-diagnostics-*" "nifi-flow-performance-*")
    
    for index in "${REQUIRED_INDICES[@]}"; do
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "$ES_AUTH_HEADER" \
            "${ELASTICSEARCH_URL}/${index}/_count")
        
        if [ "$RESPONSE" = "200" ]; then
            print_success "Index pattern ${index} exists"
        else
            print_warning "Index pattern ${index} not found (will create data view anyway)"
        fi
    done
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    print_success "curl is installed"
    
    # Check for jq (nice to have but not required)
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed (output formatting will be limited)"
    else
        print_success "jq is installed"
    fi
    
    # Check dashboard files exist
    if [ ! -d "$KIBANA_DASHBOARDS_DIR" ]; then
        print_error "Dashboard directory not found: ${KIBANA_DASHBOARDS_DIR}"
        exit 1
    fi
    print_success "Dashboard directory found"
    
    DASHBOARD_COUNT=$(find "$KIBANA_DASHBOARDS_DIR" -name "*.ndjson" | wc -l)
    if [ "$DASHBOARD_COUNT" -eq 0 ]; then
        print_error "No dashboard files (*.ndjson) found in ${KIBANA_DASHBOARDS_DIR}"
        exit 1
    fi
    print_success "Found ${DASHBOARD_COUNT} dashboard file(s)"
}

################################################################################
# Import Functions
################################################################################

create_index_patterns() {
    print_header "Creating Index Patterns (Data Views)"
    
    # Define index patterns (using pipe delimiter to avoid issues with colons in titles)
    declare -a INDEX_PATTERNS=(
        "nifi-bulletins|nifi-bulletins-*|@timestamp|NiFi Bulletins"
        "nifi-system-diagnostics|nifi-system-diagnostics-*|@timestamp|NiFi System Diagnostics"
        "nifi-flow-performance|nifi-flow-performance-*|@timestamp|NiFi Flow Performance"
        "nifi-ml-features|nifi-ml-features-hourly|@timestamp|NiFi ML Features Hourly"
        "nifi-ml-error-patterns|nifi-ml-error-patterns|@timestamp|NiFi ML Error Patterns"
    )
    
    for pattern_config in "${INDEX_PATTERNS[@]}"; do
        IFS='|' read -r id pattern time_field title <<< "$pattern_config"
        
        print_info "Creating data view: ${title}"
        
        # Create data view using Kibana 8.x API
        PAYLOAD=$(cat <<EOF
{
  "data_view": {
    "title": "${pattern}",
    "name": "${title}",
    "timeFieldName": "${time_field}"
  }
}
EOF
)
        
        RESPONSE=$(curl -s -w "\n%{http_code}" \
            -X POST "${KIBANA_URL}/api/data_views/data_view" \
            -H "kbn-xsrf: true" \
            -H "$AUTH_HEADER" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD")
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')
        
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
            print_success "Created: ${title}"
        elif [ "$HTTP_CODE" = "409" ]; then
            print_warning "Already exists: ${title}"
        else
            print_error "Failed to create ${title} (HTTP ${HTTP_CODE})"
            if command -v jq &> /dev/null; then
                echo "$BODY" | jq -r '.message // .error' 2>/dev/null || echo "$BODY"
            else
                echo "$BODY"
            fi
        fi
    done
}

import_dashboards() {
    print_header "Importing Dashboards"
    
    # Dashboard files in order
    DASHBOARD_FILES=(
        "nifi-executive-overview.ndjson"
        "nifi-bulletin-deep-dive.ndjson"
        "nifi-system-diagnostics-health.ndjson"
        "nifi-flow-performance-analytics.ndjson"
        "nifi-multi-environment-overview.ndjson"
        "nifi-historical-trends.ndjson"
        "nifi-specific-error-analysis.ndjson"
    )
    
    IMPORTED_COUNT=0
    FAILED_COUNT=0
    
    for dashboard_file in "${DASHBOARD_FILES[@]}"; do
        DASHBOARD_PATH="${KIBANA_DASHBOARDS_DIR}/${dashboard_file}"
        
        if [ ! -f "$DASHBOARD_PATH" ]; then
            print_warning "Dashboard file not found: ${dashboard_file}"
            continue
        fi
        
        print_info "Importing: ${dashboard_file}"
        
        RESPONSE=$(curl -s -w "\n%{http_code}" \
            -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
            -H "kbn-xsrf: true" \
            -H "$AUTH_HEADER" \
            --form file=@"${DASHBOARD_PATH}")
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')
        
        if [ "$HTTP_CODE" = "200" ]; then
            print_success "Imported: ${dashboard_file}"
            ((IMPORTED_COUNT++))
        else
            print_error "Failed to import ${dashboard_file} (HTTP ${HTTP_CODE})"
            ((FAILED_COUNT++))
            if command -v jq &> /dev/null; then
                echo "$BODY" | jq -r '.message // .error' 2>/dev/null || echo "$BODY"
            else
                echo "$BODY"
            fi
        fi
    done
    
    echo ""
    print_info "Import summary: ${IMPORTED_COUNT} succeeded, ${FAILED_COUNT} failed"
}

verify_dashboard_import() {
    print_header "Verifying Dashboard Import"
    
    RESPONSE=$(curl -s \
        -H "kbn-xsrf: true" \
        -H "$AUTH_HEADER" \
        "${KIBANA_URL}/api/saved_objects/_find?type=dashboard&search_fields=title&search=NiFi")
    
    if command -v jq &> /dev/null; then
        DASHBOARD_COUNT=$(echo "$RESPONSE" | jq -r '.total' 2>/dev/null || echo "0")
        
        if [ "$DASHBOARD_COUNT" -gt 0 ]; then
            print_success "Found ${DASHBOARD_COUNT} NiFi dashboard(s) in Kibana"
            
            echo ""
            print_info "Dashboard list:"
            echo "$RESPONSE" | jq -r '.saved_objects[] | "  - \(.attributes.title)"' 2>/dev/null
        else
            print_warning "No NiFi dashboards found"
        fi
    else
        print_warning "Install jq for better dashboard verification"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "NiFi Kibana Dashboard Setup"
    
    echo "This script will:"
    echo "  1. Verify Kibana connectivity"
    echo "  2. Create index patterns (data views)"
    echo "  3. Import all NiFi monitoring dashboards"
    echo "  4. Verify the import"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Collect configuration
    collect_configuration
    
    # Verify connectivity
    verify_kibana_connectivity
    
    # Verify indices (optional)
    verify_required_indices
    
    # Create index patterns
    create_index_patterns
    
    # Import dashboards
    import_dashboards
    
    # Verify import
    verify_dashboard_import
    
    # Final summary
    print_header "Setup Complete"
    
    print_success "Dashboard setup completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Navigate to Kibana: ${KIBANA_URL}"
    echo "  2. Go to Analytics → Dashboard"
    echo "  3. Open 'NiFi Executive Overview' dashboard"
    echo "  4. Verify data is appearing (adjust time range if needed)"
    echo ""
    print_info "For detailed usage instructions, see: docs/KIBANA-SETUP-GUIDE.md"
}

# Run main function
main "$@"
