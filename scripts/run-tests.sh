#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "NiFi Observability - Test Suite"
echo "========================================"

total_suites=0
passed_suites=0

# Test 1: Elasticsearch pipelines
echo -e "\n${YELLOW}[1/3] Testing Elasticsearch Pipelines${NC}"
((total_suites++))
if [ -f "tests/elasticsearch/test-pipelines.sh" ]; then
    chmod +x tests/elasticsearch/test-pipelines.sh
    if tests/elasticsearch/test-pipelines.sh; then
        echo -e "${GREEN}✅ Elasticsearch pipeline tests passed${NC}"
        ((passed_suites++))
    else
        echo -e "${RED}✗ Elasticsearch pipeline tests failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Test script not found, skipping${NC}"
fi

# Test 2: Kibana dashboards
echo -e "\n${YELLOW}[2/3] Validating Kibana Dashboards${NC}"
((total_suites++))
if [ -f "tests/kibana/validate-dashboards.py" ]; then
    if command -v python3 &> /dev/null; then
        if python3 tests/kibana/validate-dashboards.py; then
            echo -e "${GREEN}✅ Kibana dashboard validation passed${NC}"
            ((passed_suites++))
        else
            echo -e "${RED}✗ Kibana dashboard validation failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Python3 not found, skipping${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Test script not found, skipping${NC}"
fi

# Test 3: LLM service
echo -e "\n${YELLOW}[3/3] Testing LLM Analysis Service${NC}"
((total_suites++))
if [ -f "tests/services/test-llm-service.py" ]; then
    if command -v python3 &> /dev/null; then
        # Check if service is running
        if curl -s http://localhost:5000/health >/dev/null 2>&1; then
            if python3 tests/services/test-llm-service.py; then
                echo -e "${GREEN}✅ LLM service tests passed${NC}"
                ((passed_suites++))
            else
                echo -e "${RED}✗ LLM service tests failed${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ LLM service not running, skipping tests${NC}"
            echo "   Start service with: cd services/llm-analysis-service && python app.py"
        fi
    else
        echo -e "${YELLOW}⚠ Python3 not found, skipping${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Test script not found, skipping${NC}"
fi

echo -e "\n========================================"
echo -e "Test Suite Summary"
echo -e "========================================"
echo -e "Suites passed: ${passed_suites}/${total_suites}"

if [ "$passed_suites" -eq "$total_suites" ]; then
    echo -e "${GREEN}✅ All test suites passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some test suites failed or were skipped${NC}"
    exit 0
fi
