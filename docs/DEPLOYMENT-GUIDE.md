# NiFi Observability Platform - Deployment Guide

This guide provides step-by-step instructions for deploying the Apache NiFi Observability Platform.

## Prerequisites

Before you begin, ensure you have:

- **Apache NiFi 1.23.2+** installed and running
- **Elasticsearch Cloud 8.x** deployment (or self-hosted Elasticsearch)
- **Kibana 8.x** access
- **Python 3.11+** for the LLM analysis service
- **Bash shell** for running deployment scripts
- **curl** and **jq** command-line tools

## Architecture Overview

The platform consists of five main components:

1. **Elasticsearch**: Data storage, indexing, and ML capabilities
2. **Kibana**: Visualization dashboards and alerting
3. **NiFi**: Data collection and auto-remediation flows
4. **LLM Service**: AI-powered analysis (Python/Flask)
5. **Deployment Scripts**: Automation for setup

## Step 1: Clone the Repository

```bash
git clone https://github.com/talentGitHub/ApacheNiFi.git
cd ApacheNiFi
```

## Step 2: Configure Elasticsearch Cloud

### 2.1 Create Elasticsearch Cloud Deployment

1. Go to [Elastic Cloud](https://cloud.elastic.co/)
2. Create a new deployment (8.x version)
3. Note your **Cloud ID** and create an **API Key**

### 2.2 Configure Credentials

```bash
cp config/elasticsearch-cloud.yaml.example config/elasticsearch-cloud.yaml
```

Edit `config/elasticsearch-cloud.yaml` with your credentials:

```yaml
cloud_id: "your-deployment-name:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRjZWY4..."
api_key: "your-base64-encoded-api-key"
kibana_url: "https://your-deployment.kb.us-east-1.aws.found.io"
environment: "production"
cluster_name: "default"
```

## Step 3: Deploy Elasticsearch Configuration

This script creates index templates, ILM policies, and ingest pipelines.

```bash
./scripts/setup-elasticsearch.sh
```

**Expected Output:**
```
✅ ILM Policies: 3 created
✅ Ingest Pipelines: 3 created
✅ Index Templates: 3 created
✅ Initial Indices: 3 created
```

### What This Does:

- **Index Templates**: Define mappings for bulletins, system diagnostics, and flow performance
- **ILM Policies**: Set retention (30 days for bulletins, 90 days for diagnostics/performance)
- **Ingest Pipelines**: Enrich data with calculated fields, severity scores, and error categorization
- **Initial Indices**: Create first indices with write aliases

## Step 4: Import Kibana Dashboards

This script imports all 7 dashboards into Kibana.

```bash
./scripts/setup-kibana.sh
```

**Expected Output:**
```
✅ Dashboards imported: 7/7

Available Dashboards:
1. Executive Overview
2. Bulletin Deep Dive
3. System Diagnostics
4. Flow Performance
5. Multi-Environment
6. Historical Trends
7. Error Analysis
```

### Dashboard Details:

| Dashboard | Purpose | Key Metrics |
|-----------|---------|-------------|
| Executive Overview | Single-pane for stakeholders | System status, active errors, JVM memory, queue backpressure |
| Bulletin Deep Dive | Error analysis | Error timeline, top messages, category distribution, patterns |
| System Diagnostics | JVM/memory monitoring | Heap/non-heap usage, GC performance, storage, CPU, threads |
| Flow Performance | Processor optimization | Throughput trends, processing time, queue monitoring |
| Multi-Environment | Cross-site comparison | Health by environment, throughput comparison |
| Historical Trends | Capacity planning | Volume growth, storage projection, forecasting |
| Error Analysis | Critical error patterns | Port binding issues, cache failures, cascading failures |

## Step 5: Deploy ML Jobs

This script creates and starts ML anomaly detection jobs.

```bash
./scripts/deploy-ml-jobs.sh
```

**Expected Output:**
```
✅ ML Jobs created: 3
✅ Datafeeds started: 3

ML Jobs:
1. nifi-processing-anomaly - Processing time anomaly detection
2. nifi-queue-forecast - Queue growth forecasting (24h ahead)
3. nifi-error-spike - Error spike detection
```

### ML Job Details:

| Job | Bucket Span | Detects | Use Case |
|-----|-------------|---------|----------|
| Processing Anomaly | 15 minutes | Unusual execution times, abnormal invocations | Early performance degradation warning |
| Queue Forecast | 1 hour | Queue growth 24h ahead | Predictive capacity planning |
| Error Spike | 5 minutes | Unusual error patterns, rare errors | Incident detection |

## Step 6: Start Transforms

This script creates and starts continuous data transforms.

```bash
./scripts/start-transforms.sh
```

**Expected Output:**
```
✅ Transforms started: 2

Active Transforms:
1. nifi-hourly-processor-summary
2. nifi-error-pattern-analysis
```

### Transform Details:

- **Hourly Processor Summary**: Aggregates performance metrics every hour for ML training
- **Error Pattern Analysis**: Aggregates error patterns every 10 minutes for pattern recognition

## Step 7: Deploy LLM Analysis Service

### 7.1 Configure LLM Service

```bash
cd services/llm-analysis-service
cp .env.example .env
```

Edit `.env` with your LLM provider credentials:

```bash
# For OpenAI
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4-turbo-preview

# For Anthropic Claude
# LLM_PROVIDER=anthropic
# ANTHROPIC_API_KEY=sk-ant-...
```

### 7.2 Deploy with Docker

```bash
docker build -t nifi-llm-service .
docker run -d \
  -p 5000:5000 \
  --name nifi-llm-service \
  --env-file .env \
  --restart unless-stopped \
  nifi-llm-service
```

### 7.3 Verify Service

```bash
curl http://localhost:5000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "elasticsearch_connected": true,
  "llm_provider": "openai"
}
```

## Step 8: Configure NiFi Data Collection

### 8.1 Create Processors in NiFi

You need to create three processors to send data to Elasticsearch:

#### A. Bulletin Collection (Every 10 seconds)

1. Add **GetNiFiBulletins** processor
2. Add **ConvertRecord** processor (JSON → JSON)
3. Add **PutElasticsearchRecord** processor
   - Index: `nifi-bulletins`
   - Pipeline: `nifi-bulletins`

#### B. System Diagnostics (Every 1 minute)

1. Add **InvokeHTTP** processor to call NiFi API: `/nifi-api/system-diagnostics`
2. Add **EvaluateJsonPath** to extract metrics
3. Add **PutElasticsearchRecord** processor
   - Index: `nifi-system-diagnostics`
   - Pipeline: `nifi-system-diagnostics`

#### C. Flow Performance (Every 1 hour)

1. Add **InvokeHTTP** processor to call NiFi API: `/nifi-api/flow/process-groups/{id}/status`
2. Add **SplitJson** to split processors
3. Add **PutElasticsearchRecord** processor
   - Index: `nifi-flow-performance`
   - Pipeline: `nifi-flow-performance`

### 8.2 Import Auto-Remediation Template

1. In NiFi UI, go to **Templates** → **Upload Template**
2. Upload `nifi-templates/port-conflict-remediation.xml`
3. Add template to canvas
4. Configure and start the flow

## Step 9: Configure Alerting

### 9.1 Import Alert Rules

The alerting rules are defined in `alerting/nifi-alerting-rules.json`.

To import them into Kibana:

1. Go to **Stack Management** → **Rules and Connectors**
2. Create connectors for:
   - Slack (for #nifi-alerts channel)
   - Email (for ops-team@company.com)
   - PagerDuty (for P1/P2 incidents)
   - Webhook (for auto-remediation)
3. Import rules via Kibana UI or API

### 9.2 Test Alerting

Trigger a test alert:

```bash
# Simulate a critical error
curl -X POST "${ES_URL}/nifi-bulletins/_doc" \
  -H "Authorization: ApiKey ${ES_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "@timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
    "bulletinLevel": "ERROR",
    "bulletinMessage": "Test alert",
    "bulletinSourceName": "TestProcessor",
    "bulletinSourceType": "Processor",
    "environment": "production"
  }'
```

## Step 10: Verify Deployment

Run the verification script:

```bash
./scripts/verify-deployment.sh
```

**Expected Output:**
```
✅ All checks passed! System is fully deployed.

Verification Results: 8/8 checks passed
```

## Post-Deployment

### Access Dashboards

- **Kibana URL**: `https://your-deployment.kb.io`
- **Dashboards**: Stack Management → Kibana → Dashboards

### Monitor ML Jobs

- **ML Jobs**: Machine Learning → Anomaly Detection → Jobs
- Check job status and view anomalies

### View Transforms

- **Transforms**: Stack Management → Data → Transforms
- Monitor transform health and statistics

### Test LLM Analysis

```bash
# Analyze a bulletin
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_id": "your-bulletin-id"
  }'
```

## Troubleshooting

### Elasticsearch Connection Issues

```bash
# Test connection
curl -X GET "${ES_URL}/_cluster/health" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

### ML Jobs Not Starting

```bash
# Check ML job status
curl -X GET "${ES_URL}/_ml/anomaly_detectors/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

### Dashboards Not Loading

- Verify index patterns exist in Kibana
- Check that data is flowing into indices
- Verify time range in dashboard filters

### LLM Service Errors

```bash
# Check service logs
docker logs nifi-llm-service

# Verify health
curl http://localhost:5000/health
```

## Next Steps

1. **Customize dashboards** for your specific use cases
2. **Tune ML jobs** based on your data patterns
3. **Configure additional alerting** rules
4. **Set up auto-remediation** workflows
5. **Train team** on using the platform

## Support

- **Documentation**: [docs/](../docs/)
- **Issues**: https://github.com/talentGitHub/ApacheNiFi/issues
- **Discussions**: https://github.com/talentGitHub/ApacheNiFi/discussions

---

**Congratulations!** Your NiFi Observability Platform is now fully deployed.
