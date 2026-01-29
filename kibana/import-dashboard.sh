#!/bin/bash
#
# Quick Import Script for System Health Dashboard
# This script imports the System Health Dashboard into Kibana
#
# Usage: ./import-dashboard.sh [KIBANA_URL]
#
# Example: ./import-dashboard.sh https://my-kibana.kb.cloud
#
# Security Note: Credentials are prompted interactively to avoid exposure
# in command history or process lists. For automated imports, consider
# using API keys instead of username/password authentication.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
KIBANA_URL="${1:-${KIBANA_URL}}"
DASHBOARD_FILE="kibana/dashboards/system-health-dashboard.ndjson"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  System Health Dashboard Import Script${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Check if dashboard file exists
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo -e "${RED}✗ Error: Dashboard file not found: $DASHBOARD_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Dashboard file found${NC}"

# Check if KIBANA_URL is provided
if [ -z "$KIBANA_URL" ]; then
    echo -e "${RED}✗ Error: KIBANA_URL not provided${NC}"
    echo
    echo "Usage: $0 <KIBANA_URL>"
    echo
    echo "Example:"
    echo "  $0 https://my-deployment.kb.cloud"
    echo
    echo "Or set the KIBANA_URL environment variable:"
    echo "  export KIBANA_URL=https://my-deployment.kb.cloud"
    echo "  $0"
    exit 1
fi

echo -e "${GREEN}✓ Kibana URL: $KIBANA_URL${NC}"
echo

# Prompt for credentials
echo -e "${YELLOW}Please enter your Kibana credentials:${NC}"
read -p "Username: " KIBANA_USER
read -s -p "Password: " KIBANA_PASSWORD
echo
echo

# Validate credentials are provided
if [ -z "$KIBANA_USER" ] || [ -z "$KIBANA_PASSWORD" ]; then
    echo -e "${RED}✗ Error: Username and password are required${NC}"
    exit 1
fi

echo -e "${YELLOW}Importing dashboard...${NC}"

# Import the dashboard
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: multipart/form-data" \
    -u "${KIBANA_USER}:${KIBANA_PASSWORD}" \
    -F "file=@${DASHBOARD_FILE}")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
# Extract response body (everything except last line)
BODY=$(echo "$RESPONSE" | head -n -1)

echo

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Dashboard imported successfully!${NC}"
    echo
    echo "Response:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Next Steps${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "1. Go to Kibana: $KIBANA_URL/app/dashboards"
    echo "2. Search for 'System Health Dashboard'"
    echo "3. Configure your time range and refresh interval"
    echo
    echo -e "${YELLOW}Note: Ensure you have created the 'nifi-diag*' index pattern${NC}"
    echo "      and that NiFi is sending data to Elasticsearch."
    echo
else
    echo -e "${RED}✗ Failed to import dashboard${NC}"
    echo -e "${RED}HTTP Status Code: $HTTP_CODE${NC}"
    echo
    echo "Response:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    echo
    echo -e "${RED}Troubleshooting:${NC}"
    echo "- Verify your Kibana URL is correct"
    echo "- Check your credentials"
    echo "- Ensure you have 'kibana_admin' role or saved objects write permissions"
    echo "  (Contact your Elasticsearch administrator to verify permissions)"
    echo "- Review the Kibana logs for more details"
    exit 1
fi
