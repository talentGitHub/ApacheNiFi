# Deployment Guide

Complete step-by-step deployment instructions for the Apache NiFi Observability Platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Components

- **Apache NiFi**: Version 1.23.2 or higher
- **Elasticsearch Cloud**: Version 8.x deployment
- **Kibana**: Version 8.x (included with Elasticsearch Cloud)
- **Python**: 3.11+ for LLM analysis service
- **Bash Shell**: For running deployment scripts

### Required Tools

```bash
# Install required command-line tools
# On Ubuntu/Debian:
sudo apt-get update
sudo apt-get install -y curl jq python3 python3-pip python3-yaml

# On macOS:
brew install curl jq python3
pip3 install pyyaml

# Optional but recommended:
pip3 install yq
```

### Access Requirements

- Elasticsearch Cloud API key or username/password
- Kibana access with appropriate permissions
- (Optional) OpenAI or Anthropic API key for LLM service
- Network access from NiFi to Elasticsearch

## Installation Steps

### Step 1: Clone Repository

```bash
git clone https://github.com/talentGitHub/ApacheNiFi.git
cd ApacheNiFi
```

### Step 2: Configure Credentials

```bash
# Copy example configuration
cp config/elasticsearch-cloud.yaml.example config/elasticsearch-cloud.yaml

# Edit configuration with your credentials
nano config/elasticsearch-cloud.yaml  # or vim, code, etc.
```

Required configuration:
- Elasticsearch host URL
- API key or username/password
- Kibana host URL
- NiFi instance URL

### Step 3: Deploy Elasticsearch Components

```bash
# Create index templates, ILM policies, and ingest pipelines
./scripts/setup-elasticsearch.sh
```

Expected output:
```
✅ Connected to Elasticsearch
✅ Creating ILM policies (3/3)
✅ Creating ingest pipelines (3/3)
✅ Creating index templates (3/3)
✅ Creating initial indices (3/3)
```

### Step 4: Import Kibana Dashboards

```bash
# Import all 7 dashboards
./scripts/setup-kibana.sh
```

Expected output:
```
✅ Connected to Kibana
✅ Creating index patterns (3/3)
✅ Importing dashboards (7/7)
```

Access dashboards at: `https://your-kibana.kb.io/app/dashboards`

### Step 5: Deploy Machine Learning Jobs

```bash
# Create and start ML anomaly detection jobs
./scripts/deploy-ml-jobs.sh
```

This creates:
- Processing Time Anomaly Detection
- Queue Growth Forecasting
- Error Spike Detection

### Step 6: Start Data Transforms

```bash
# Start continuous transforms for feature aggregation
./scripts/start-transforms.sh
```

This starts:
- Hourly Processor Performance Summary
- Error Pattern Analysis

### Step 7: Deploy LLM Analysis Service (Optional)

```bash
cd services/llm-analysis-service

# Copy and configure environment
cp .env.example .env
nano .env  # Add your API keys

# Build Docker image
docker build -t nifi-llm-service .

# Run the service
docker run -d \
  -p 5000:5000 \
  --env-file .env \
  --name nifi-llm-service \
  --restart unless-stopped \
  nifi-llm-service
```

Test the service:
```bash
curl http://localhost:5000/health
```

### Step 8: Configure NiFi Data Export

You need to configure NiFi to send data to Elasticsearch. There are two approaches:

#### Approach A: Using PutElasticsearchHttp Processor

1. Open NiFi UI
2. Add `PutElasticsearchHttp` processor for each data stream
3. Configure:
   - **Elasticsearch URL**: Your Elasticsearch Cloud endpoint
   - **Index**: Use aliases (nifi-bulletins, nifi-system-diagnostics, etc.)
   - **Type**: `_doc`
   - **Identifier Attribute**: `bulletinId`, `nodeId`, or `componentId`
   - **Batch Size**: 100

#### Approach B: Using NiFi Templates

1. Download processor templates from `nifi-templates/` directory
2. Import via NiFi UI → Upload Template
3. Instantiate templates and configure with your Elasticsearch endpoint

### Step 9: Import Auto-Remediation Templates (Optional)

```bash
# Import NiFi templates via UI
# 1. Go to NiFi UI → Templates → Upload Template
# 2. Upload the following templates:
#    - nifi-templates/port-conflict-resolution.xml
#    - nifi-templates/memory-error-handler.xml
#    - nifi-templates/backpressure-releaser.xml
# 3. Drag templates onto canvas and configure
```

## Configuration

### Elasticsearch Index Lifecycle

Default retention policies:
- **Bulletins**: 30 days
- **System Diagnostics**: 90 days
- **Flow Performance**: 90 days

To modify, edit `elasticsearch/ilm-policies/*.json` and redeploy.

### ML Job Tuning

To adjust ML sensitivity:

```bash
# Edit ML job configuration
nano ml/jobs/nifi-processing-anomaly.json

# Modify bucket_span or detection thresholds
# Redeploy
./scripts/deploy-ml-jobs.sh
```

### Dashboard Refresh Rates

Default: 30 seconds for real-time dashboards

To change, edit `kibana/dashboards/*.ndjson` and modify `refreshInterval`.

## Verification

Run comprehensive verification:

```bash
./scripts/verify-deployment.sh
```

Expected output:
```
✅ Elasticsearch components (10/10)
✅ Kibana dashboards (7/7)
✅ ML jobs (3/3)
✅ Transforms (2/2)
✅ Project structure verified
```

### Manual Verification Checklist

- [ ] Elasticsearch indices are being created
- [ ] Data is flowing from NiFi to Elasticsearch
- [ ] Dashboards display data
- [ ] ML jobs are running
- [ ] Transforms are processing
- [ ] LLM service responds to health checks
- [ ] Alerts are configured (if applicable)

## Post-Deployment

### 1. Configure Alerting

Set up alerting rules based on your requirements. See [Kibana Alerting Documentation](https://www.elastic.co/guide/en/kibana/current/alerting-getting-started.html).

### 2. Set Up Notifications

Configure notification channels:
- Slack webhooks
- Email SMTP settings
- PagerDuty integration

### 3. Monitor ML Jobs

Allow 1-2 hours for ML models to train with initial data. Monitor progress in Kibana ML app.

### 4. Fine-tune Dashboards

Customize dashboards based on your specific use cases and KPIs.

### 5. Schedule Regular Maintenance

- Review ILM policies monthly
- Validate ML model performance
- Update dashboard visualizations as needed
- Review and update auto-remediation logic

## Rollback

If you need to rollback:

```bash
# Delete ML jobs
curl -X DELETE "$ES_HOST/_ml/anomaly_detectors/nifi-*"

# Stop transforms
curl -X POST "$ES_HOST/_transform/nifi-*/_stop"

# Delete transforms
curl -X DELETE "$ES_HOST/_transform/nifi-*"

# Delete indices (WARNING: This deletes all data!)
curl -X DELETE "$ES_HOST/nifi-*"

# Stop LLM service
docker stop nifi-llm-service
docker rm nifi-llm-service
```

## Next Steps

- [Architecture Documentation](ARCHITECTURE.md)
- [User Guide](USER-GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [API Reference](API-REFERENCE.md)
