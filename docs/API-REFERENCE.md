# API Reference - LLM Analysis Service

## Overview

The LLM Analysis Service provides AI-powered root cause analysis and remediation recommendations for Apache NiFi bulletins.

**Base URL**: `http://localhost:5000`

**Version**: 1.0.0

## Authentication

Currently, the service does not require authentication for local deployments. For production deployments, consider implementing:
- API key authentication
- OAuth 2.0
- Network-level security (VPN, firewall rules)

## Endpoints

### Health Check

Check the service health and configuration.

**Endpoint**: `GET /health`

**Parameters**: None

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-28T15:37:00.000Z",
  "elasticsearch": "connected",
  "llm_provider": "openai"
}
```

**Response Fields**:
- `status` (string): Service status ("healthy" or "unhealthy")
- `timestamp` (string): Current server time in ISO 8601 format
- `elasticsearch` (string): Elasticsearch connection status ("connected", "not configured", "error")
- `llm_provider` (string): Configured LLM provider ("openai", "anthropic", "azure", etc.)

**Status Codes**:
- `200 OK`: Service is healthy
- `503 Service Unavailable`: Service is unhealthy

**Example**:
```bash
curl -X GET http://localhost:5000/health
```

---

### Analyze Bulletin

Analyze a single NiFi bulletin and provide root cause analysis and recommendations.

**Endpoint**: `POST /analyze`

**Content-Type**: `application/json`

**Request Body**:
```json
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
}
```

**Request Fields**:
- `bulletin_id` (string, required): The unique identifier of the bulletin to analyze

**Response**:
```json
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
  "analysis": {
    "root_cause": "DistributedMapCacheServer port 4558 conflict with existing process",
    "immediate_actions": [
      "Stop conflicting service on port 4558",
      "Restart DistributedMapCacheServer",
      "Verify port availability before enabling"
    ],
    "prevention": [
      "Configure dynamic port allocation",
      "Implement port conflict detection in startup scripts",
      "Add pre-flight checks to controller service activation"
    ],
    "impact": "High - Service unavailable, downstream processors blocked",
    "confidence": 0.92
  },
  "timestamp": "2026-01-28T18:30:00.000Z"
}
```

**Response Fields**:
- `bulletin_id` (string): The bulletin ID that was analyzed
- `analysis` (object): Analysis results
  - `root_cause` (string): Identified root cause of the issue
  - `immediate_actions` (array of strings): Actions to resolve the issue immediately
  - `prevention` (array of strings): Long-term prevention strategies
  - `impact` (string): Impact assessment (High/Medium/Low with description)
  - `confidence` (number): Confidence score (0.0 to 1.0)
- `timestamp` (string): Analysis timestamp in ISO 8601 format

**Status Codes**:
- `200 OK`: Analysis completed successfully
- `400 Bad Request`: Invalid request body (missing bulletin_id)
- `404 Not Found`: Bulletin not found in Elasticsearch
- `500 Internal Server Error`: Service error (LLM API failure, etc.)

**Example**:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
  }'
```

**Error Response**:
```json
{
  "error": "bulletin_id is required"
}
```

---

### Batch Analyze

Analyze multiple bulletins in a single request.

**Endpoint**: `POST /batch-analyze`

**Content-Type**: `application/json`

**Request Body**:
```json
{
  "bulletin_ids": [
    "480e958b-ec48-4890-a3be-b9154f963403",
    "5a1f876c-df39-4a91-b4cf-d0265g074504",
    "6b2g987d-eg40-5b02-c5dg-e1376h185615"
  ]
}
```

**Request Fields**:
- `bulletin_ids` (array of strings, required): Array of bulletin IDs to analyze

**Response**:
```json
{
  "results": [
    {
      "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
      "analysis": {
        "root_cause": "...",
        "immediate_actions": [...],
        "prevention": [...],
        "impact": "High",
        "confidence": 0.92
      }
    },
    {
      "bulletin_id": "5a1f876c-df39-4a91-b4cf-d0265g074504",
      "analysis": {
        "root_cause": "...",
        "immediate_actions": [...],
        "prevention": [...],
        "impact": "Medium",
        "confidence": 0.85
      }
    }
  ],
  "timestamp": "2026-01-28T18:30:00.000Z"
}
```

**Response Fields**:
- `results` (array): Array of analysis results
  - Each item contains `bulletin_id` and `analysis` (same structure as single analyze)
- `timestamp` (string): Batch analysis timestamp

**Status Codes**:
- `200 OK`: Batch analysis completed (even if some bulletins not found)
- `400 Bad Request`: Invalid request body (missing bulletin_ids array)
- `500 Internal Server Error`: Service error

**Example**:
```bash
curl -X POST http://localhost:5000/batch-analyze \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_ids": [
      "480e958b-ec48-4890-a3be-b9154f963403",
      "5a1f876c-df39-4a91-b4cf-d0265g074504"
    ]
  }'
```

---

## Data Models

### Bulletin Context

The service gathers the following context when analyzing a bulletin:

```json
{
  "bulletin": {
    "bulletinId": "string",
    "bulletinLevel": "ERROR|WARN|INFO",
    "bulletinMessage": "string",
    "bulletinSourceName": "string",
    "bulletinSourceType": "PROCESSOR|CONTROLLER_SERVICE|...",
    "bulletinCategory": "PORT_CONFLICT|MEMORY|TIMEOUT|...",
    "@timestamp": "ISO 8601 timestamp",
    "severityScore": 1-3,
    "extractedPort": 4558,
    "nodeAddress": "string",
    "environment": "string"
  },
  "related_bulletins": [
    {
      "bulletinMessage": "string",
      "@timestamp": "ISO 8601 timestamp",
      "...": "..."
    }
  ],
  "system_metrics": [
    {
      "heapUtilization": 80.5,
      "totalThreads": 250,
      "processorLoadAverage": 3.5,
      "@timestamp": "ISO 8601 timestamp",
      "...": "..."
    }
  ]
}
```

### Analysis Response

```json
{
  "root_cause": "string",
  "immediate_actions": ["string", "string", ...],
  "prevention": ["string", "string", ...],
  "impact": "High|Medium|Low - description",
  "confidence": 0.0-1.0
}
```

## Configuration

### Environment Variables

The service is configured using environment variables (typically in `.env` file):

```bash
# Elasticsearch Configuration
ES_CLOUD_ID=your-deployment:base64string
ES_API_KEY=your-api-key

# LLM Configuration
LLM_PROVIDER=openai|anthropic|azure|custom
LLM_API_KEY=your-llm-api-key
LLM_MODEL=gpt-4-turbo|claude-3-opus|...

# Azure OpenAI (if using azure provider)
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=your-deployment-name

# Service Configuration
PORT=5000
```

### Supported LLM Providers

#### OpenAI

```bash
LLM_PROVIDER=openai
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4-turbo
```

**Supported Models**:
- `gpt-4-turbo`
- `gpt-4`
- `gpt-3.5-turbo`

#### Anthropic Claude

```bash
LLM_PROVIDER=anthropic
LLM_API_KEY=sk-ant-...
LLM_MODEL=claude-3-opus-20240229
```

**Supported Models**:
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`

#### Azure OpenAI

```bash
LLM_PROVIDER=azure
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=your-deployment-name
LLM_API_KEY=your-azure-key
```

#### Custom LLM Endpoint

```bash
LLM_PROVIDER=custom
LLM_API_KEY=your-api-key
LLM_ENDPOINT=http://localhost:11434/api/generate  # Ollama example
LLM_MODEL=llama2
```

## Error Handling

### Error Response Format

All errors return a JSON response with an error field:

```json
{
  "error": "Error message description"
}
```

### Common Error Codes

- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Bulletin not found in Elasticsearch
- `500 Internal Server Error`: Service error
- `503 Service Unavailable`: Service unhealthy

### Error Examples

**Missing bulletin_id**:
```json
{
  "error": "bulletin_id is required"
}
```

**Bulletin not found**:
```json
{
  "error": "Bulletin not found or Elasticsearch not configured"
}
```

**LLM API error**:
```json
{
  "error": "LLM provider API error: Rate limit exceeded"
}
```

## Rate Limiting

The service does not implement rate limiting by default. Consider implementing:

- API gateway with rate limiting
- LLM provider rate limits (e.g., OpenAI: 3500 requests/minute)
- Request queuing for high load scenarios
- Caching for repeated bulletin analyses

## Best Practices

### Performance

1. **Batch Requests**: Use `/batch-analyze` for multiple bulletins
2. **Caching**: Implement caching for frequently analyzed bulletins
3. **Async Processing**: Consider async processing for large batches
4. **Timeout Handling**: Set appropriate timeouts (default: 120s)

### Security

1. **API Key Rotation**: Rotate LLM provider API keys regularly
2. **Data Sanitization**: Service automatically removes sensitive data
3. **Network Security**: Deploy behind firewall/VPN
4. **Audit Logging**: Log all analysis requests for compliance

### Cost Optimization

1. **Model Selection**: Use cheaper models for non-critical analysis
2. **Token Management**: Minimize prompt size
3. **Caching**: Cache common error patterns
4. **Batching**: Batch requests to reduce API calls

## Examples

### Python

```python
import requests

# Health check
response = requests.get('http://localhost:5000/health')
print(response.json())

# Analyze bulletin
response = requests.post(
    'http://localhost:5000/analyze',
    json={'bulletin_id': '480e958b-ec48-4890-a3be-b9154f963403'}
)
analysis = response.json()
print(f"Root cause: {analysis['analysis']['root_cause']}")
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

// Health check
axios.get('http://localhost:5000/health')
  .then(response => console.log(response.data));

// Analyze bulletin
axios.post('http://localhost:5000/analyze', {
  bulletin_id: '480e958b-ec48-4890-a3be-b9154f963403'
})
  .then(response => {
    console.log('Root cause:', response.data.analysis.root_cause);
  });
```

### Bash/cURL

```bash
# Health check
curl http://localhost:5000/health | jq

# Analyze bulletin
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{"bulletin_id":"480e958b-ec48-4890-a3be-b9154f963403"}' \
  | jq '.analysis.root_cause'

# Batch analyze
curl -X POST http://localhost:5000/batch-analyze \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_ids": [
      "480e958b-ec48-4890-a3be-b9154f963403",
      "5a1f876c-df39-4a91-b4cf-d0265g074504"
    ]
  }' | jq '.results[].analysis.root_cause'
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/talentGitHub/ApacheNiFi/issues
- Email: support@your-company.com
- Documentation: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**API Version**: 1.0.0  
**Last Updated**: 2026-01-28  
**Service Repository**: https://github.com/talentGitHub/ApacheNiFi
