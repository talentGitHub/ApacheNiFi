# Apache NiFi Observability Platform - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Elasticsearch Configuration](#elasticsearch-configuration)
4. [Kibana Setup](#kibana-setup)
5. [Machine Learning Deployment](#machine-learning-deployment)
6. [LLM Analysis Service](#llm-analysis-service)
7. [NiFi Integration](#nifi-integration)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Apache NiFi**: Version 1.23.2 or higher
- **Elasticsearch Cloud**: Version 8.x deployment
- **Kibana**: Version 8.x (included with Elasticsearch Cloud)
- **Python**: Version 3.11 or higher (for LLM service)
- **Docker**: (Optional) For containerized LLM service
- **Bash**: Unix shell for running deployment scripts
- **curl**: For API calls during setup

### Required Credentials
- Elasticsearch Cloud deployment ID and API key
- LLM provider API key (OpenAI, Anthropic, or Azure)
- NiFi access credentials (if authentication enabled)

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/talentGitHub/ApacheNiFi.git
cd ApacheNiFi
```

### 2. Configure Environment

Copy the example configuration file:

```bash
cp config/elasticsearch-cloud.yaml.example config/elasticsearch-cloud.yaml
```

Edit `config/elasticsearch-cloud.yaml` with your credentials:

```yaml
elasticsearch:
  cloud_id: "your-deployment:base64encodedstring"
  api_key: "your-api-key-here"

kibana:
  endpoint: "https://your-kibana.kb.io"

nifi:
  endpoint: "http://localhost:8080/nifi-api"

llm:
  provider: "openai"
  api_key: "your-llm-api-key"
  model: "gpt-4-turbo"
```

## Elasticsearch Configuration

### Deploy Index Templates, ILM Policies, and Ingest Pipelines

Run the Elasticsearch setup script:

```bash
./scripts/setup-elasticsearch.sh
```

This script will:
- Create ILM policies for data retention (30 days for bulletins, 90 days for metrics)
- Create ingest pipelines for data enrichment
- Create index templates with proper mappings
- Initialize the first indices with write aliases

**Expected Output:**
```
Step 1: Creating ILM Policies...
  - Creating policy: nifi-bulletins-ilm... ✓
  - Creating policy: nifi-system-diagnostics-ilm... ✓
  - Creating policy: nifi-flow-performance-ilm... ✓

Step 2: Creating Ingest Pipelines...
  - Creating pipeline: nifi-bulletins-enrichment... ✓
  - Creating pipeline: nifi-system-diagnostics-enrichment... ✓
  - Creating pipeline: nifi-flow-performance-enrichment... ✓

Step 3: Creating Index Templates...
  - Creating template: nifi-bulletins... ✓
  - Creating template: nifi-system-diagnostics... ✓
  - Creating template: nifi-flow-performance... ✓
```

### Verify Elasticsearch Setup

```bash
# Check if templates exist
curl -X GET "https://your-es-endpoint.es.io/_index_template" \
  -H "Authorization: ApiKey YOUR_API_KEY"

# Check if ILM policies exist
curl -X GET "https://your-es-endpoint.es.io/_ilm/policy" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

## Kibana Setup

### Import Dashboards and Create Data Views

Run the Kibana setup script:

```bash
./scripts/setup-kibana.sh
```

This script will:
- Create index patterns for all data streams
- Create data views (Kibana 8.x)
- Import pre-configured dashboards

**Expected Output:**
```
Step 1: Importing Kibana Dashboards...
  - Importing dashboard: nifi-executive-overview... ✓
  - Importing dashboard: nifi-bulletin-deep-dive... ✓
  (... 5 more dashboards)

Step 2: Creating Index Patterns...
  - Creating index pattern: nifi-bulletins-*... ✓
  - Creating index pattern: nifi-system-diagnostics-*... ✓
```

### Access Dashboards

Navigate to Kibana:
```
https://your-kibana.kb.io/app/dashboards
```

Available dashboards:
1. **[NiFi] Executive Overview** - High-level KPIs and system status
2. **[NiFi] Bulletin Deep Dive** - Error analysis and troubleshooting
3. **[NiFi] System Diagnostics Health** - JVM and resource monitoring
4. **[NiFi] Flow Performance Analytics** - Processor performance metrics
5. **[NiFi] Multi-Environment Overview** - Cross-site comparison
6. **[NiFi] Historical Trends & Capacity Planning** - Long-term analysis
7. **[NiFi] Specific Error Analysis** - Critical error patterns

## Machine Learning Deployment

### Deploy ML Jobs

Run the ML deployment script:

```bash
./scripts/deploy-ml-jobs.sh
```

This creates and starts:
- **nifi-processing-anomaly**: Detects unusual processor execution times
- **nifi-queue-forecast**: Forecasts queue sizes 24 hours ahead
- **nifi-error-spike**: Detects unusual error patterns

### Start Transforms

Run the transforms script:

```bash
./scripts/start-transforms.sh
```

This creates and starts:
- **nifi-hourly-processor-performance**: Hourly aggregation for ML training
- **nifi-error-pattern-analysis**: Error pattern aggregation

### Verify ML Jobs

```bash
# Check ML job status
curl -X GET "https://your-es-endpoint.es.io/_ml/anomaly_detectors/_stats" \
  -H "Authorization: ApiKey YOUR_API_KEY"

# Check transform status
curl -X GET "https://your-es-endpoint.es.io/_transform/_stats" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

## LLM Analysis Service

### Option 1: Run with Docker

```bash
cd services/llm-analysis-service

# Create .env file
cp .env.example .env
# Edit .env with your credentials

# Build Docker image
docker build -t nifi-llm-service .

# Run container
docker run -d \
  --name nifi-llm-service \
  -p 5000:5000 \
  --env-file .env \
  nifi-llm-service
```

### Option 2: Run with Python

```bash
cd services/llm-analysis-service

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your credentials

# Run service
python app.py
```

### Verify LLM Service

```bash
# Health check
curl http://localhost:5000/health

# Expected response:
# {
#   "status": "healthy",
#   "timestamp": "2026-01-28T15:37:00.000Z",
#   "elasticsearch": "connected",
#   "llm_provider": "openai"
# }
```

## NiFi Integration

### Configure NiFi Data Collection

1. **Import Self-Healing Template**
   - Open NiFi UI: http://localhost:8080/nifi
   - Go to Templates → Upload Template
   - Select `nifi-templates/self-healing-flow.xml`

2. **Configure PutElasticsearch Processors**
   - Add processors to send bulletins, system diagnostics, and flow metrics
   - Configure Elasticsearch connection with your Cloud ID and API key
   - Set appropriate scheduling:
     - Bulletins: Every 10 seconds
     - System Diagnostics: Every 1 minute
     - Flow Performance: Every 1 hour

3. **Enable Ingest Pipelines**
   - In PutElasticsearch processors, set pipeline parameter:
     - Bulletins → `nifi-bulletins-enrichment`
     - System Diagnostics → `nifi-system-diagnostics-enrichment`
     - Flow Performance → `nifi-flow-performance-enrichment`

## Verification

### Run Complete Verification

```bash
./scripts/verify-deployment.sh
```

**Expected Output:**
```
=== Elasticsearch Configuration ===
✅ Index template: nifi-bulletins
✅ Index template: nifi-system-diagnostics
✅ Index template: nifi-flow-performance
✅ ILM policy: nifi-bulletins-ilm
✅ ILM policy: nifi-system-diagnostics-ilm
✅ ILM policy: nifi-flow-performance-ilm
✅ Ingest pipeline: nifi-bulletins-enrichment
✅ Ingest pipeline: nifi-system-diagnostics-enrichment
✅ Ingest pipeline: nifi-flow-performance-enrichment

=== Machine Learning ===
✅ ML jobs running (3/3)
✅ Transforms processing (2/2)

=== Kibana Dashboards ===
✅ Kibana dashboards loaded (7/7)

=== LLM Service ===
✅ LLM service responsive

Checks passed: 14/14
✅ All checks passed!
```

### Run Tests

```bash
./scripts/run-tests.sh
```

## Troubleshooting

### Common Issues

#### Elasticsearch Connection Failed
```bash
# Verify credentials
curl -X GET "https://your-es-endpoint.es.io/" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

#### ML Jobs Not Starting
```bash
# Check if indices have data
curl -X GET "https://your-es-endpoint.es.io/nifi-*/_search?size=1"

# ML jobs need data to start
```

#### LLM Service Not Responding
```bash
# Check logs
docker logs nifi-llm-service

# Or if running with Python
python app.py  # Check console output
```

### Getting Help

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions
- Open an issue: https://github.com/talentGitHub/ApacheNiFi/issues
- Email support: support@your-company.com

## Next Steps

1. Configure alerting rules in Kibana
2. Set up notification channels (Slack, email, PagerDuty)
3. Customize dashboards for your environment
4. Fine-tune ML job parameters based on your data patterns
5. Implement custom auto-remediation workflows

## Production Considerations

- **Security**: Enable TLS, configure RBAC, use secure credentials
- **Scaling**: Adjust ES cluster size, ML job resources, LLM service replicas
- **Backup**: Configure snapshot repository for Elasticsearch
- **Monitoring**: Monitor the monitoring stack itself
- **Cost**: Review Elasticsearch Cloud and LLM API costs regularly
