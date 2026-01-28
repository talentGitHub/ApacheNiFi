# LLM Analysis Service

This service provides AI-powered analysis of Apache NiFi bulletins using LLM providers.

## Features

- Root cause analysis of NiFi errors
- Contextual insights from bulletins and system metrics
- Remediation recommendations
- Support for multiple LLM providers (OpenAI, Anthropic, Azure)

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your credentials
```

3. Run locally:
```bash
python app.py
```

4. Or use Docker:
```bash
docker build -t nifi-llm-service .
docker run -d -p 5000:5000 --env-file .env nifi-llm-service
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

### Batch Analysis
```bash
POST /batch-analyze
Content-Type: application/json

{
  "bulletin_ids": ["id1", "id2", "id3"]
}
```

## Configuration

### Environment Variables

- `ES_CLOUD_ID`: Elasticsearch Cloud deployment ID
- `ES_API_KEY`: Elasticsearch API key
- `LLM_PROVIDER`: LLM provider (openai, anthropic, azure)
- `LLM_API_KEY`: API key for LLM provider
- `LLM_MODEL`: Model name (e.g., gpt-4-turbo, claude-3-opus)
- `PORT`: Service port (default: 5000)

## Supported LLM Providers

### OpenAI
```bash
LLM_PROVIDER=openai
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4-turbo
```

### Anthropic Claude
```bash
LLM_PROVIDER=anthropic
LLM_API_KEY=sk-ant-...
LLM_MODEL=claude-3-opus-20240229
```

### Azure OpenAI
```bash
LLM_PROVIDER=azure
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=your-deployment-name
```
