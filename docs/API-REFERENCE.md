# API Reference

Complete API documentation for the LLM Analysis Service.

## Base URL

```
http://localhost:5000
```

## Authentication

Currently no authentication required. Service should be deployed on internal network only.

## Endpoints

### GET /health

Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "elasticsearch": true,
  "llm_provider": "openai",
  "llm_configured": true
}
```

**Status Codes**:
- `200`: Service healthy
- `503`: Service unhealthy

---

### POST /analyze

Analyze a single bulletin and provide root cause analysis.

**Request Body**:
```json
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
}
```

**Response**:
```json
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
  "analysis": {
    "root_cause": "DistributedMapCacheServer port 4558 conflict",
    "immediate_actions": [
      "Check process using port: lsof -i :4558",
      "Stop conflicting service",
      "Restart DistributedMapCacheServer"
    ],
    "prevention": [
      "Configure dynamic port allocation",
      "Add port conflict detection",
      "Document port assignments"
    ],
    "impact": "High - Service unavailable",
    "confidence": 0.92
  },
  "timestamp": "2026-01-28T18:30:00.000Z"
}
```

**Status Codes**:
- `200`: Analysis successful
- `400`: Invalid request (missing bulletin_id)
- `404`: Bulletin not found
- `500`: Analysis failed

---

### POST /analyze/batch

Analyze multiple bulletins.

**Request Body**:
```json
{
  "bulletin_ids": [
    "480e958b-ec48-4890-a3be-b9154f963403",
    "591f069c-fd59-5a01-b0cf-c0265g074514"
  ]
}
```

**Response**:
```json
{
  "results": [
    {
      "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
      "analysis": { ... }
    },
    {
      "bulletin_id": "591f069c-fd59-5a01-b0cf-c0265g074514",
      "analysis": { ... }
    }
  ],
  "count": 2
}
```

**Limits**:
- Maximum 10 bulletins per request

**Status Codes**:
- `200`: Batch analysis successful
- `400`: Invalid request

---

### GET /recent-errors

Get recent error bulletins.

**Query Parameters**:
- `minutes` (optional): Time window in minutes (default: 60, max: 1440)

**Example**:
```
GET /recent-errors?minutes=30
```

**Response**:
```json
{
  "count": 15,
  "bulletins": [
    {
      "bulletinId": "...",
      "bulletinLevel": "ERROR",
      "bulletinMessage": "...",
      "@timestamp": "2026-01-28T18:00:00.000Z"
    },
    ...
  ]
}
```

**Status Codes**:
- `200`: Request successful
- `500`: Query failed

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Detailed error message"
}
```

## Rate Limiting

No rate limiting currently implemented. Recommended to implement at load balancer level:
- 100 requests per minute per IP
- 10 concurrent requests per IP

## Examples

### Using curl

```bash
# Health check
curl http://localhost:5000/health

# Analyze single bulletin
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{"bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"}'

# Batch analysis
curl -X POST http://localhost:5000/analyze/batch \
  -H "Content-Type: application/json" \
  -d '{"bulletin_ids": ["id1", "id2"]}'

# Recent errors
curl http://localhost:5000/recent-errors?minutes=30
```

### Using Python

```python
import requests

# Analyze bulletin
response = requests.post(
    'http://localhost:5000/analyze',
    json={'bulletin_id': '480e958b-ec48-4890-a3be-b9154f963403'}
)

if response.status_code == 200:
    analysis = response.json()
    print(f"Root cause: {analysis['analysis']['root_cause']}")
    print(f"Confidence: {analysis['analysis']['confidence']}")
```

### Using JavaScript

```javascript
// Analyze bulletin
fetch('http://localhost:5000/analyze', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    bulletin_id: '480e958b-ec48-4890-a3be-b9154f963403'
  })
})
.then(response => response.json())
.then(data => {
  console.log('Root cause:', data.analysis.root_cause);
  console.log('Confidence:', data.analysis.confidence);
});
```

## Integration Examples

### NiFi InvokeHTTP Processor

Configure InvokeHTTP processor:
- **HTTP Method**: POST
- **Remote URL**: http://llm-service:5000/analyze
- **Content-Type**: application/json
- **Request Body**: `{"bulletin_id": "${bulletinId}"}`

### Kibana Webhook Action

Configure webhook action in alerting rule:
- **URL**: http://llm-service:5000/analyze
- **Method**: POST
- **Headers**: `Content-Type: application/json`
- **Body**: `{"bulletin_id": "{{context.bulletinId}}"}`

## Monitoring

Monitor these metrics:
- Request rate (requests/sec)
- Response time (p50, p95, p99)
- Error rate
- LLM API cost
- Elasticsearch query time

Metrics available via standard Flask logging.
