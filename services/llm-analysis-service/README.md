# NiFi LLM Analysis Service

AI-powered root cause analysis and remediation recommendations for Apache NiFi.

## Features

- Root cause analysis using GPT-4 or Claude 3
- Contextual insights from Elasticsearch data
- Immediate action recommendations
- Long-term prevention strategies
- Impact assessment and confidence scoring
- Auto-remediation webhook endpoint

## Quick Start

### Docker (Recommended)

```bash
# Build the image
docker build -t nifi-llm-service .

# Run the container
docker run -d \
  -p 5000:5000 \
  --env-file .env \
  --name nifi-llm-service \
  nifi-llm-service
```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env
# Edit .env with your credentials

# Run the service
python app.py
```

## API Endpoints

### Health Check

```bash
GET /health

Response:
{
  "status": "healthy",
  "timestamp": "2026-01-28T18:30:00.000Z",
  "elasticsearch_connected": true,
  "llm_provider": "openai"
}
```

### Analyze Bulletin

```bash
POST /analyze
Content-Type: application/json

{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
}

Response:
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
  "analysis": {
    "root_cause": "DistributedMapCacheServer port 4558 conflict...",
    "immediate_actions": [
      "Stop conflicting service on port 4558",
      "Restart DistributedMapCacheServer",
      "Verify port availability before enabling"
    ],
    "prevention": [
      "Configure dynamic port allocation",
      "Implement port conflict detection",
      "Add pre-flight checks"
    ],
    "impact": "High - Service unavailable",
    "confidence": 0.92
  },
  "timestamp": "2026-01-28T18:30:00.000Z",
  "provider": "openai"
}
```

### Remediation Webhook

```bash
POST /remediate
Content-Type: application/json

{
  "alert_type": "port_conflict",
  "port": "4558",
  "component": "DistributedMapCacheServer"
}

Response:
{
  "status": "acknowledged",
  "alert_type": "port_conflict",
  "timestamp": "2026-01-28T18:30:00.000Z"
}
```

## Configuration

### Supported LLM Providers

- **OpenAI**: GPT-4, GPT-4-turbo
- **Anthropic**: Claude 3 Opus, Claude 3 Sonnet
- **Azure OpenAI**: Enterprise GPT-4 deployment
- **Custom**: Ollama, LLaMA, or any OpenAI-compatible API

### Environment Variables

See `.env.example` for all configuration options.

## Development

```bash
# Install development dependencies
pip install -r requirements.txt pytest black flake8

# Run tests
pytest

# Format code
black .

# Lint code
flake8 .
```

## Docker Compose

```yaml
version: '3.8'

services:
  llm-service:
    build: .
    ports:
      - "5000:5000"
    environment:
      - ES_CLOUD_ID=${ES_CLOUD_ID}
      - ES_API_KEY=${ES_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LLM_PROVIDER=openai
    restart: unless-stopped
```

## Security

- API keys are never logged or exposed
- PII data is anonymized before sending to LLM
- All communications use TLS/SSL
- Audit logging for all analysis requests

## License

MIT License - See LICENSE file for details
