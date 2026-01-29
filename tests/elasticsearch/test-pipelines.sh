#!/bin/bash

# Test Elasticsearch ingest pipelines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Testing Elasticsearch Pipelines..."

# Test bulletin pipeline with sample data
echo "Testing nifi-bulletins-pipeline..."
RESULT=$(curl -s -X POST "http://localhost:9200/_ingest/pipeline/nifi-bulletins-pipeline/_simulate" \
  -H "Content-Type: application/json" \
  -d '{
    "docs": [
      {
        "_source": {
          "bulletinLevel": "ERROR",
          "bulletinMessage": "Unable to start controller service. Address already in use on port 4558",
          "bulletinSourceName": "DistributedMapCacheServer",
          "bulletinTimestamp": "2026-01-28T18:00:00.000Z"
        }
      }
    ]
  }')

if echo "$RESULT" | grep -q "errorCategory"; then
    echo "✅ Bulletin pipeline test passed"
else
    echo "❌ Bulletin pipeline test failed"
    exit 1
fi

echo "All pipeline tests passed!"
