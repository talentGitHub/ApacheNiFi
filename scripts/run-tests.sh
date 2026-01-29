#!/bin/bash

# Run all tests for NiFi Observability Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "  NiFi Observability Platform"
echo "  Test Suite"
echo "========================================="
echo ""

# Track test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

run_test_suite() {
    local name=$1
    local command=$2
    
    ((TOTAL_SUITES++))
    echo -e "${BLUE}Running: $name${NC}"
    
    if eval "$command"; then
        echo -e "${GREEN}✅ $name passed${NC}"
        ((PASSED_SUITES++))
    else
        echo -e "${RED}❌ $name failed${NC}"
        ((FAILED_SUITES++))
    fi
    echo ""
}

# 1. Elasticsearch Pipeline Tests
if [ -x "$PROJECT_ROOT/tests/elasticsearch/test-pipelines.sh" ]; then
    run_test_suite "Elasticsearch Pipelines" "$PROJECT_ROOT/tests/elasticsearch/test-pipelines.sh"
else
    echo -e "${BLUE}Skipping: Elasticsearch tests (not executable)${NC}"
    echo ""
fi

# 2. Kibana Dashboard Tests
if [ -f "$PROJECT_ROOT/tests/kibana/validate-dashboards.py" ] && command -v python3 &> /dev/null; then
    run_test_suite "Kibana Dashboards" "cd $PROJECT_ROOT/tests/kibana && python3 validate-dashboards.py"
else
    echo -e "${BLUE}Skipping: Kibana tests (missing python3 or script)${NC}"
    echo ""
fi

# 3. LLM Service Tests
if [ -f "$PROJECT_ROOT/tests/services/test-llm-service.py" ] && command -v python3 &> /dev/null; then
    run_test_suite "LLM Analysis Service" "cd $PROJECT_ROOT/tests/services && python3 test-llm-service.py"
else
    echo -e "${BLUE}Skipping: LLM service tests (missing python3 or script)${NC}"
    echo ""
fi

# 4. Integration Tests
if [ -x "$PROJECT_ROOT/tests/integration-test.sh" ]; then
    run_test_suite "Integration Tests" "$PROJECT_ROOT/tests/integration-test.sh"
else
    echo -e "${BLUE}Skipping: Integration tests (not executable)${NC}"
    echo ""
fi

# Summary
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo "Total test suites: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
echo -e "${RED}Failed: $FAILED_SUITES${NC}"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
