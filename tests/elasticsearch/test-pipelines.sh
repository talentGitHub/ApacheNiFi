#!/bin/bash
set -e

echo "========================================" 
echo "Testing Elasticsearch Ingest Pipelines"
echo "========================================"

# Load configuration
CONFIG_FILE="../../config/elasticsearch-cloud.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "✗ Configuration file not found"
    exit 1
fi

# Parse config (simplified)
if [ -z "$ES_CLOUD_ID" ] || [ -z "$ES_API_KEY" ]; then
    echo "⚠ Please set ES_CLOUD_ID and ES_API_KEY environment variables"
    exit 1
fi

ES_ENDPOINT=$(echo "$ES_CLOUD_ID" | cut -d':' -f2 | base64 -d | cut -d'$' -f1)
ES_URL="https://${ES_ENDPOINT}.es.io"

# Test bulletins enrichment pipeline
echo "Testing bulletins enrichment pipeline..."
test_doc='{
  "docs": [
    {
      "_source": {
        "bulletinLevel": "ERROR",
        "bulletinMessage": "Failed to start DistributedMapCacheServer due to java.net.BindException: Address already in use port 4558",
        "bulletinSourceName": "DistributedMapCacheServer",
        "bulletinTimestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"
      }
    }
  ]
}'

response=$(curl -s -X POST "${ES_URL}/_ingest/pipeline/nifi-bulletins-enrichment/_simulate" \
    -H "Authorization: ApiKey ${ES_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$test_doc")

if echo "$response" | grep -q "severityScore"; then
    echo "✅ Bulletins pipeline test passed"
else
    echo "✗ Bulletins pipeline test failed"
    echo "$response"
fi

# Test system diagnostics enrichment
echo -e "\nTesting system diagnostics enrichment pipeline..."
test_doc2='{
  "docs": [
    {
      "_source": {
        "usedHeapBytes": 8589934592,
        "maxHeapBytes": 10737418240,
        "contentRepositoryStorageUsage": {
          "freeSpaceBytes": 50000000000,
          "totalSpaceBytes": 100000000000
        }
      }
    }
  ]
}'

response=$(curl -s -X POST "${ES_URL}/_ingest/pipeline/nifi-system-diagnostics-enrichment/_simulate" \
    -H "Authorization: ApiKey ${ES_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$test_doc2")

if echo "$response" | grep -q "heapUtilization"; then
    echo "✅ System diagnostics pipeline test passed"
else
    echo "✗ System diagnostics pipeline test failed"
    echo "$response"
fi

echo -e "\n✅ All pipeline tests completed"
