# Quick Start Guide - NiFi Observability Platform

## 🚀 Getting Started in 5 Minutes

This guide helps you deploy the complete observability platform quickly.

## Prerequisites Checklist

- [ ] Elasticsearch Cloud 8.x deployment (or self-hosted)
- [ ] Cloud ID and API Key ready
- [ ] Apache NiFi 1.23.2+ running
- [ ] Bash shell and curl installed

## Step 1: Clone and Configure (1 minute)

```bash
# Clone the repository
git clone https://github.com/talentGitHub/ApacheNiFi.git
cd ApacheNiFi

# Copy and edit configuration
cp config/elasticsearch-cloud.yaml.example config/elasticsearch-cloud.yaml
# Edit with your Elasticsearch credentials
```

## Step 2: Deploy Elasticsearch (1 minute)

```bash
# Create index templates, ILM policies, and pipelines
./scripts/setup-elasticsearch.sh
```

Expected output:
```
✅ ILM Policies: 3 created
✅ Ingest Pipelines: 3 created
✅ Index Templates: 3 created
✅ Initial Indices: 3 created
```

## Step 3: Import Dashboards (1 minute)

```bash
# Import all 7 Kibana dashboards
./scripts/setup-kibana.sh
```

Expected output:
```
✅ Dashboards imported: 7/7
```

## Step 4: Deploy ML Jobs (1 minute)

```bash
# Create and start ML anomaly detection
./scripts/deploy-ml-jobs.sh

# Start continuous transforms
./scripts/start-transforms.sh
```

Expected output:
```
✅ ML Jobs: 3/3 running
✅ Transforms: 2/2 running
```

## Step 5: Verify Deployment (1 minute)

```bash
# Run comprehensive verification
./scripts/verify-deployment.sh
```

Expected output:
```
✅ All checks passed! System is fully deployed.
```

## 🎉 You're Done!

Open Kibana and navigate to:
- Dashboards → Executive Overview
- Machine Learning → Anomaly Detection
- Stack Management → Transforms

## Optional: Deploy LLM Service

```bash
cd services/llm-analysis-service
cp .env.example .env
# Edit .env with your OpenAI/Anthropic API key

# Deploy with Docker
docker build -t nifi-llm-service .
docker run -d -p 5000:5000 --env-file .env nifi-llm-service

# Test
curl http://localhost:5000/health
```

## Next Steps

1. **Configure NiFi Data Collection**: Set up processors to send data to Elasticsearch
   - See DEPLOYMENT-GUIDE.md Step 8 for details
   
2. **Explore Dashboards**: Navigate through all 7 dashboards in Kibana
   - See USER-GUIDE.md for usage instructions
   
3. **Configure Alerting**: Set up Slack/Email/PagerDuty connectors
   - Import rules from `alerting/nifi-alerting-rules.json`
   
4. **Import NiFi Template**: Upload auto-remediation template
   - Use `nifi-templates/port-conflict-remediation.xml`

## Troubleshooting

### Connection Issues
```bash
# Test Elasticsearch connection
curl -X GET "${ES_URL}/_cluster/health" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

### Dashboard Not Loading
- Check that data is flowing into indices
- Verify time range in dashboard (default: Last 15 minutes)
- Ensure index patterns are created

### ML Jobs Not Starting
```bash
# Check ML job status
curl -X GET "${ES_URL}/_ml/anomaly_detectors/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

## What You Get

✅ **7 Production Dashboards** with 50+ visualizations  
✅ **3 ML Anomaly Detection Jobs** for predictive monitoring  
✅ **7 Alerting Rules** with multi-channel notifications  
✅ **LLM-Powered Analysis** for root cause investigation  
✅ **Auto-Remediation** workflows for common issues  

## Documentation

- **Full Deployment Guide**: [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)
- **Dashboard Usage**: [docs/USER-GUIDE.md](docs/USER-GUIDE.md)
- **Implementation Details**: [docs/IMPLEMENTATION-SUMMARY.md](docs/IMPLEMENTATION-SUMMARY.md)

## Support

- **Issues**: https://github.com/talentGitHub/ApacheNiFi/issues
- **Discussions**: https://github.com/talentGitHub/ApacheNiFi/discussions

---

**Total Setup Time**: ~5 minutes  
**Deployment Complexity**: Low (automated scripts)  
**Production Ready**: Yes ✅
