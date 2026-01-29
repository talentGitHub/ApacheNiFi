# NiFi LLM Analysis Service

AI-powered root cause analysis and remediation recommendations for Apache NiFi bulletins.

## Features

- 🔍 **Root Cause Analysis**: Identifies the underlying cause of errors
- 🚀 **Immediate Actions**: Provides step-by-step remediation guidance
- 🛡️ **Prevention Strategies**: Recommends long-term solutions
- 📊 **Impact Assessment**: Evaluates severity and business impact
- 🤖 **Multi-LLM Support**: Works with OpenAI, Anthropic, and Azure OpenAI

## Setup

### Using Docker

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
```

### Analyze Single Bulletin
```bash
POST /analyze
Content-Type: application/json

{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
}
```

### Analyze Multiple Bulletins
```bash
POST /analyze/batch
Content-Type: application/json

{
  "bulletin_ids": [
    "480e958b-ec48-4890-a3be-b9154f963403",
    "591f069c-fd59-5a01-b0cf-c0265g074514"
  ]
}
```

### Get Recent Errors
```bash
GET /recent-errors?minutes=60
```

## Example Response

```json
{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403",
  "analysis": {
    "root_cause": "DistributedMapCacheServer port 4558 conflict with existing process",
    "immediate_actions": [
      "Check which process is using port 4558 with: lsof -i :4558",
      "Stop the conflicting service",
      "Restart DistributedMapCacheServer",
      "Verify port availability before enabling"
    ],
    "prevention": [
      "Configure dynamic port allocation",
      "Implement port conflict detection in startup scripts",
      "Add pre-flight checks to controller service activation",
      "Document port assignments for all services"
    ],
    "impact": "High - Service unavailable, downstream processors blocked",
    "confidence": 0.92
  },
  "timestamp": "2026-01-28T18:30:00.000Z"
}
```

## Configuration

See `.env.example` for all configuration options.

## LLM Provider Setup

### OpenAI
1. Get API key from https://platform.openai.com/api-keys
2. Set `LLM_PROVIDER=openai`
3. Set `OPENAI_API_KEY=your_key`

### Anthropic
1. Get API key from https://console.anthropic.com/
2. Set `LLM_PROVIDER=anthropic`
3. Set `ANTHROPIC_API_KEY=your_key`

### Azure OpenAI
1. Create Azure OpenAI resource
2. Deploy a model
3. Set Azure-specific environment variables

## Monitoring

The service logs all analysis requests and stores results in Elasticsearch index `nifi-analysis-results` for auditing and trend analysis.
