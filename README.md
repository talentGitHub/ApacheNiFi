# Apache NiFi Observability Platform

> Enterprise-grade monitoring, analytics, and intelligent automation for Apache NiFi 1.23.2

## 🎯 Overview

This platform provides comprehensive observability for Apache NiFi deployments, featuring:

- **Real-time Monitoring**: 7 production-ready dashboards with 50+ visualizations (Kibana by default, [other options available](ALTERNATIVES.md))
- **Machine Learning**: Anomaly detection, predictive analytics, and capacity forecasting
- **Intelligent Alerting**: 7 critical alerting rules with multi-channel notifications
- **AI-Powered Analysis**: LLM integration for root cause analysis and remediation recommendations
- **Auto-Remediation**: Self-healing workflows for common issues
- **Flexible Visualization**: Works with Kibana, Grafana, Apache Superset, and more ([see alternatives](ALTERNATIVES.md))

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Apache NiFi 1.23.2                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Bulletins   │  │ System Diag  │  │     Flow     │      │
│  │  (10 sec)    │  │   (1 min)    │  │  (1 hour)    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│               Elasticsearch Cloud (8.x)                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Index Templates │ ILM Policies │ Ingest Pipelines  │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │    ML Jobs      │  Transforms  │  Anomaly Detection│   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kibana (8.x)                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Dashboards  │  │   Alerts     │  │    Canvas    │     │
│  │   (7 sets)   │  │  (7 rules)   │  │  (Reports)   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              LLM Analysis Service (Python)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Root Cause Analysis │ Auto-Remediation │ AI Agent  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Data Streams

### 1. Bulletins (Every 10 seconds)
- **Purpose**: Error tracking, real-time alerts
- **Fields**: bulletinLevel, bulletinMessage, bulletinSourceName, bulletinSourceType, bulletinGroupName
- **Retention**: 30 days
- **Enrichments**: Severity scoring, error categorization, port extraction

### 2. System Diagnostics (Every 1 minute)
- **Purpose**: JVM health, memory, storage, GC monitoring
- **Fields**: heapUtilization, usedHeapBytes, maxHeapBytes, processorLoadAverage, totalThreads, storageUsage
- **Retention**: 90 days
- **Enrichments**: Percentage normalization, nested structure parsing

### 3. Flow Performance (Every 1 hour)
- **Purpose**: Throughput, latency, processor performance
- **Fields**: componentName, processorType, runStatus, bytesTransferred, processingNanos, queuedCount
- **Retention**: 90 days
- **Enrichments**: Processing efficiency, queue utilization, throughput rate

## 🚀 Quick Start

### Prerequisites

- Apache NiFi 1.23.2+ running
- Elasticsearch Cloud 8.x deployment
- Kibana 8.x access (or see [ALTERNATIVES.md](ALTERNATIVES.md) for other visualization options)
- Python 3.11+ (for LLM service)
- Bash shell (for deployment scripts)

> **💡 Looking for alternatives to Kibana?** 
> - **Quick decision guide**: [QUICK-START-ALTERNATIVES.md](QUICK-START-ALTERNATIVES.md) (5-minute read)
> - **Detailed documentation**: [ALTERNATIVES.md](ALTERNATIVES.md) (Complete setup guides for Grafana, Superset, Prometheus, Metabase, and more)

### Installation

```bash
# 1. Clone repository
git clone https://github.com/talentGitHub/ApacheNiFi.git
cd ApacheNiFi

# 2. Configure environment
cp config/elasticsearch-cloud.yaml.example config/elasticsearch-cloud.yaml
# Edit with your Elasticsearch Cloud credentials

# 3. Deploy Elasticsearch configurations
./scripts/setup-elasticsearch.sh

# 4. Import Kibana dashboards
./scripts/setup-kibana.sh

# 5. Deploy ML jobs and transforms
./scripts/deploy-ml-jobs.sh
./scripts/start-transforms.sh

# 6. Start LLM analysis service
cd services/llm-analysis-service
docker build -t nifi-llm-service .
docker run -d -p 5000:5000 --env-file .env nifi-llm-service

# 7. Import NiFi auto-remediation templates
# Upload nifi-templates/self-healing-flow.xml via NiFi UI
```

### Verification

```bash
# Run comprehensive verification
./scripts/verify-deployment.sh

# Expected output:
# ✅ Elasticsearch templates created
# ✅ ILM policies active
# ✅ Ingest pipelines configured
# ✅ ML jobs running (3/3)
# ✅ Transforms processing (2/2)
# ✅ Kibana dashboards loaded (7/7)
# ✅ Alerting rules configured (7/7)
# ✅ LLM service responsive
```

## 📈 Dashboards

### 1. Executive Overview
**Purpose**: Single-pane-of-glass for stakeholders  
**Refresh**: 30 seconds  
**Key Panels**:
- System Status KPI
- Active Errors (last 5 min)
- JVM Memory Utilization with thresholds
- Error Rate Timeline
- Queue Backpressure Gauge
- Processor Health Heatmap

**Access**: `https://your-kibana.kb.io/app/dashboards#/view/nifi-executive-overview`

### 2. Bulletin Deep Dive
**Purpose**: Comprehensive error analysis and troubleshooting  
**Key Panels**:
- Bulletins Over Time (ERROR/WARN/INFO breakdown)
- Top 10 Error Messages with counts
- Error Distribution by category
- Time-based patterns (hour × day heatmap)
- Live bulletin stream with search

### 3. System Diagnostics Health
**Purpose**: JVM, memory, storage, GC monitoring  
**Key Panels**:
- Heap & Non-Heap usage gauges
- GC performance (count rate + duration)
- Storage utilization by repository
- CPU & thread metrics
- Historical comparison table

### 4. Flow Performance Analytics
**Purpose**: Processor and connection performance optimization  
**Key Panels**:
- Throughput trends (read/write/transfer rates)
- Top processors by processing time
- Processor statistics table
- Queue backpressure monitoring
- Connection details
- Record processing metrics

### 5. Multi-Environment Overview
**Purpose**: Cross-site comparative monitoring  
**Key Panels**:
- Environment health cards
- Throughput comparison by environment
- Cross-environment error rate
- Resource utilization radar chart

### 6. Historical Trends & Capacity Planning
**Purpose**: Long-term analysis and forecasting  
**Key Panels**:
- Data processing volume growth (with 30-day ML forecast)
- Storage growth projection
- Capacity projections table
- Processor duration distribution
- SLA compliance goal

### 7. Specific Error Analysis
**Purpose**: Deep dive into critical error patterns  
**Focus**:
- Port binding issues (Address already in use)
- DistributedMapCacheServer failures
- Cascading failure analysis with Sankey diagram

## 🤖 Machine Learning Capabilities

### Anomaly Detection Jobs

#### 1. Processing Time Anomaly Detection
- **Job ID**: `nifi-processing-anomaly`
- **Bucket Span**: 15 minutes
- **Detects**: Unusual processor execution times, abnormal invocation counts
- **Use Case**: Early warning for performance degradation

#### 2. Queue Growth Forecasting
- **Job ID**: `nifi-queue-forecast`
- **Bucket Span**: 1 hour
- **Forecasts**: Queue size 24 hours ahead
- **Use Case**: Predictive capacity planning, prevent backpressure

#### 3. Error Spike Detection
- **Job ID**: `nifi-error-spike`
- **Bucket Span**: 5 minutes
- **Detects**: Unusual error patterns, rare error types
- **Use Case**: Incident detection, root cause correlation

### Continuous Transforms

#### 1. Hourly Processor Performance Summary
- **Aggregates**: Processing times, invocations, throughput, error rates
- **Frequency**: Every hour
- **Destination**: `nifi-ml-features-hourly`
- **Use Case**: ML model training, historical analysis

#### 2. Error Pattern Analysis
- **Aggregates**: Error counts by category, source, time-of-day
- **Frequency**: Every 10 minutes
- **Destination**: `nifi-ml-error-patterns`
- **Use Case**: Pattern recognition, predictive alerting

## 🚨 Alerting Rules

### Critical Alerts (P1/P2)

1. **Critical Error Alert**: ERROR bulletins from critical services (>3 in 5 min)
2. **JVM Memory Critical**: Heap utilization >85% for 5 minutes
3. **Port Binding Failure**: Immediate alert on "Address already in use"
4. **Processor Invalid State**: Any processor in Invalid runStatus

### Warning Alerts (P3)

5. **Queue Backpressure Warning**: >80% utilization for 10 minutes
6. **Storage Capacity Warning**: >85% utilization for 15 minutes
7. **GC Pause Time High**: Average >500ms

### Notification Channels

- **Slack**: `#nifi-alerts`, `#nifi-infrastructure`
- **Email**: ops-team@company.com, infrastructure-team@company.com
- **PagerDuty**: P1/P2 incidents
- **Webhook**: Auto-remediation triggers

## 🧠 LLM Analysis Service

### Features

- **Root Cause Analysis**: AI-powered incident investigation
- **Contextual Insights**: Gathers bulletins + metrics + historical patterns
- **Remediation Recommendations**: Immediate actions + long-term strategies
- **Impact Assessment**: High/Medium/Low severity classification

### API Endpoints

```bash
# Analyze bulletin incident
POST http://localhost:5000/analyze
Content-Type: application/json

{
  "bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"
}

# Response
{
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

### Supported LLM Providers

- OpenAI GPT-4 / GPT-4-turbo
- Anthropic Claude 3 Opus / Sonnet
- Azure OpenAI Service
- Custom LLM endpoints (Ollama, LLaMA, etc.)

## 🔧 Auto-Remediation

### Self-Healing Workflows

The platform includes NiFi templates for automated issue resolution:

#### 1. Port Conflict Resolution
```groovy
// Detects: "Address already in use"
// Actions:
// - Identify conflicting process
// - Stop NiFi controller service
// - Release port
// - Restart service with validation
```

#### 2. Memory Error Handler
```groovy
// Detects: Heap memory >90%, OOM warnings
// Actions:
// - Trigger emergency GC
// - Stop non-critical processors
// - Clear expired flowfiles
// - Notify operations team
```

#### 3. Backpressure Releaser
```groovy
// Detects: Queue >95% capacity
// Actions:
// - Increase concurrent tasks temporarily
// - Drop expired flowfiles
// - Enable alternative routing
// - Scale processor threads
```

### Audit Trail

All automated actions are logged to `nifi-remediation-audit` index:

```json
{
  "@timestamp": "2026-01-28T18:35:00.000Z",
  "action": "SERVICE_DISABLED",
  "component": "DistributedMapCacheServer",
  "reason": "Port 4558 conflict detected",
  "triggered_by": "auto-remediation-flow",
  "result": "success",
  "duration_ms": 1250
}
```

## 📚 Documentation

- **[Quick Start: Choosing an Alternative](QUICK-START-ALTERNATIVES.md)**: 5-minute guide to selecting the best Kibana alternative for your needs
- **[Alternatives to Kibana](ALTERNATIVES.md)**: Comprehensive guide to alternative visualization platforms (Grafana, Superset, Prometheus, etc.)
- **[Deployment Guide](docs/DEPLOYMENT-GUIDE.md)**: Step-by-step installation instructions
- **[Architecture](docs/ARCHITECTURE.md)**: System design and component interactions
- **[User Guide](docs/USER-GUIDE.md)**: Dashboard usage and navigation
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[API Reference](docs/API-REFERENCE.md)**: LLM service API documentation

## 🧪 Testing

```bash
# Run all tests
./scripts/run-tests.sh

# Test specific components
cd tests/elasticsearch
./test-pipelines.sh

cd tests/kibana
python validate-dashboards.py

cd tests/services
python test-llm-service.py
```

## 📊 Success Metrics

### Technical KPIs
- **MTTD (Mean Time to Detection)**: < 1 minute
- **MTTR (Mean Time to Resolution)**: < 15 minutes (auto-remediated)
- **False Positive Rate**: < 5%
- **ML Prediction Accuracy**: > 90%

### Business KPIs
- **System Uptime**: 99.9%
- **Manual Intervention Reduction**: 70% in 6 months
- **Incident Response Cost**: 40% reduction

## 🔒 Security

- **Elasticsearch**: TLS/SSL, API keys, RBAC
- **Kibana**: Role-based access, space isolation
- **LLM Service**: Data anonymization, PII removal, audit logging
- **NiFi**: Encrypted credentials, approval workflows

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apache NiFi community
- Elastic Stack team
- OpenAI / Anthropic for LLM capabilities

## 📞 Support

- **Issues**: https://github.com/talentGitHub/ApacheNiFi/issues
- **Discussions**: https://github.com/talentGitHub/ApacheNiFi/discussions
- **Email**: support@your-company.com

## 🗺️ Roadmap

### Q1 2026
- [x] Core monitoring dashboards
- [x] ML anomaly detection
- [ ] LLM integration (Beta)
- [ ] Auto-remediation (Beta)

### Q2 2026
- [ ] Multi-cluster support
- [ ] Advanced forecasting models
- [ ] Custom alerting workflows
- [ ] Mobile dashboard app

### Q3 2026
- [ ] AIOps full automation
- [ ] Predictive maintenance
- [ ] Cost optimization recommendations
- [ ] Integration with ITSM tools

---

**Built with ❤️ by the Platform Engineering Team**

**Version**: 1.0.0  
**Last Updated**: 2026-01-28
