# User Guide - Apache NiFi Observability Platform

## Introduction

This guide will help you navigate and use the Apache NiFi Observability Platform dashboards and features effectively.

## Accessing the Platform

### Kibana Dashboards

Navigate to your Kibana instance:
```
https://your-kibana.kb.io/app/dashboards
```

Filter by "NiFi" to see all available dashboards.

## Dashboard Guide

### 1. Executive Overview Dashboard

**Purpose**: High-level system status for stakeholders and management.

**When to Use**: 
- Daily status checks
- Stakeholder meetings
- Quick system health assessment

**Key Panels**:
- **System Status KPI**: Overall health indicator (Green/Yellow/Red)
- **Active Errors (Last 5 min)**: Real-time error count
- **JVM Memory Utilization**: Heap usage with threshold indicators
- **Error Rate Timeline**: Trend of errors over time
- **Queue Backpressure Gauge**: Percentage of queues at capacity
- **Processor Health Heatmap**: Visual grid of processor states

**How to Interpret**:
- Green status = All systems operational
- Yellow status = Warnings present, investigation recommended
- Red status = Critical issues, immediate action required

### 2. Bulletin Deep Dive Dashboard

**Purpose**: Comprehensive error analysis and troubleshooting.

**When to Use**:
- Investigating specific errors
- Troubleshooting incidents
- Error trend analysis

**Key Panels**:
- **Bulletins Over Time**: ERROR/WARN/INFO breakdown
- **Top 10 Error Messages**: Most frequent errors with counts
- **Error Distribution by Category**: PORT_CONFLICT, MEMORY, TIMEOUT, etc.
- **Time-based Patterns**: Heatmap showing errors by hour and day
- **Live Bulletin Stream**: Real-time error log with search capability

**Filters Available**:
- Bulletin Level (ERROR, WARN, INFO)
- Source Component
- Error Category
- Time Range

**Pro Tips**:
- Use the search bar to filter for specific error messages
- Click on error categories to drill down
- Export error lists for reporting

### 3. System Diagnostics Health Dashboard

**Purpose**: Monitor JVM health, memory, storage, and garbage collection.

**When to Use**:
- Performance tuning
- Capacity planning
- Memory leak investigation
- GC optimization

**Key Panels**:
- **Heap & Non-Heap Gauges**: Current memory utilization
- **GC Performance**: Collection count rate and duration
- **Storage Utilization by Repository**: Content, FlowFile, Provenance
- **CPU & Thread Metrics**: Load average and thread counts
- **Historical Comparison Table**: Week-over-week metrics

**Alert Thresholds**:
- Heap >85%: Warning
- Heap >95%: Critical
- Storage >85%: Warning
- GC pauses >500ms: Warning

### 4. Flow Performance Analytics Dashboard

**Purpose**: Optimize processor and connection performance.

**When to Use**:
- Performance optimization
- Identifying bottlenecks
- Capacity planning
- SLA monitoring

**Key Panels**:
- **Throughput Trends**: Read/write/transfer rates over time
- **Top Processors by Processing Time**: Identify slow processors
- **Processor Statistics Table**: Detailed metrics per processor
- **Queue Backpressure Monitoring**: Queues approaching capacity
- **Connection Details**: FlowFile transfer statistics
- **Record Processing Metrics**: Record-level performance

**Performance Optimization Tips**:
- Look for processors with high processing time but low invocation count
- Identify queues consistently near capacity
- Monitor processors with "Invalid" status

### 5. Multi-Environment Overview Dashboard

**Purpose**: Compare metrics across multiple NiFi environments.

**When to Use**:
- Managing Dev/Test/Prod environments
- Cross-site monitoring
- Environment comparison

**Key Panels**:
- **Environment Health Cards**: Status per environment
- **Throughput Comparison by Environment**: Side-by-side metrics
- **Cross-Environment Error Rate**: Error trends across sites
- **Resource Utilization Radar Chart**: CPU, memory, storage comparison

**Setup Requirements**:
- Tag data with `environment` field during collection
- Configure environment filters in dashboard

### 6. Historical Trends & Capacity Planning Dashboard

**Purpose**: Long-term analysis and forecasting with ML predictions.

**When to Use**:
- Quarterly capacity reviews
- Budget planning
- Growth projections
- SLA compliance reporting

**Key Panels**:
- **Data Processing Volume Growth**: 30-day trend with ML forecast
- **Storage Growth Projection**: Predicted storage needs
- **Capacity Projections Table**: CPU, memory, storage estimates
- **Processor Duration Distribution**: Performance patterns over time
- **SLA Compliance Goal**: Percentage meeting SLA targets

**ML Predictions**:
- Queue size forecasts (24 hours ahead)
- Storage growth projections (30 days ahead)
- Processing time anomalies

### 7. Specific Error Analysis Dashboard

**Purpose**: Deep dive into critical error patterns.

**When to Use**:
- Troubleshooting specific error types
- Port binding issues
- DistributedMapCacheServer failures
- Cascading failure analysis

**Focus Areas**:
- Port conflicts ("Address already in use")
- Service startup failures
- Resource contention
- Cascading failure chains

**Features**:
- Pre-filtered for critical error categories
- Sankey diagram for failure cascade visualization
- Correlation with system metrics

## Using the LLM Analysis Service

### Analyzing a Bulletin

When you encounter an error in Kibana:

1. **Copy the Bulletin ID** from the bulletin detail view
2. **Make API request**:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{"bulletin_id": "480e958b-ec48-4890-a3be-b9154f963403"}'
```

3. **Review the response**:
```json
{
  "analysis": {
    "root_cause": "DistributedMapCacheServer port 4558 conflict",
    "immediate_actions": [
      "Stop conflicting service on port 4558",
      "Restart DistributedMapCacheServer"
    ],
    "prevention": [
      "Configure dynamic port allocation",
      "Add pre-flight checks"
    ],
    "impact": "High",
    "confidence": 0.92
  }
}
```

### Batch Analysis

Analyze multiple bulletins at once:
```bash
curl -X POST http://localhost:5000/batch-analyze \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_ids": ["id1", "id2", "id3"]
  }'
```

## Common Workflows

### Daily Health Check Routine

1. Open **Executive Overview** dashboard
2. Check system status KPI
3. Review active errors count
4. Check memory utilization
5. If issues found, drill down to **Bulletin Deep Dive**

### Incident Investigation

1. Start with **Bulletin Deep Dive** dashboard
2. Filter by time range of incident
3. Identify error patterns and top errors
4. Use LLM service to analyze critical bulletins
5. Check **System Diagnostics** for resource issues
6. Review **Flow Performance** for bottlenecks
7. Document findings and remediation actions

### Performance Optimization

1. Open **Flow Performance Analytics** dashboard
2. Identify top processors by processing time
3. Check queue backpressure indicators
4. Review **Historical Trends** for patterns
5. Use insights to adjust:
   - Concurrent tasks
   - Back pressure thresholds
   - Processor scheduling
   - Resource allocation

### Capacity Planning

1. Open **Historical Trends & Capacity Planning**
2. Review ML forecasts for queue growth
3. Check storage growth projections
4. Analyze processor duration trends
5. Create capacity plan based on projections
6. Present findings using exported reports

## Alerting Setup

### Creating an Alert Rule

1. Navigate to Kibana → Stack Management → Rules and Connectors
2. Click "Create rule"
3. Choose rule type: "Elasticsearch query"
4. Configure:
   - **Index**: `nifi-bulletins-*`
   - **Query**: `bulletinLevel: "ERROR"`
   - **Threshold**: Count > 3 in 5 minutes
   - **Actions**: Send notification

### Alert Examples

**Critical Error Alert**:
```
When: ERROR bulletins from critical services
Threshold: >3 in 5 minutes
Actions: Slack, Email, PagerDuty
```

**JVM Memory Critical**:
```
When: heapUtilization > 85%
Threshold: For 5 minutes
Actions: Slack, Email
```

**Queue Backpressure**:
```
When: queueUtilization > 80%
Threshold: For 10 minutes
Actions: Slack
```

## Exporting and Reporting

### Dashboard Export

1. Open dashboard
2. Click Share → Export
3. Choose format (PDF, PNG, CSV)
4. Configure options
5. Download

### Scheduled Reports

1. Navigate to Kibana → Stack Management → Reporting
2. Create schedule
3. Select dashboard
4. Choose recipients
5. Set frequency (daily, weekly, monthly)

## Best Practices

### Dashboard Usage
- Set appropriate time ranges (last 24h for operations, last 90d for trends)
- Use filters to focus on specific environments or components
- Bookmark frequently used dashboards
- Customize refresh intervals based on needs

### Alert Management
- Start with conservative thresholds
- Tune based on false positive rate
- Document alert responses
- Review and update rules quarterly

### Performance
- Limit dashboard panels to essential visualizations
- Use appropriate time ranges
- Archive old data per ILM policies
- Monitor Elasticsearch cluster health

## Troubleshooting Common Issues

### Dashboard Not Loading
- Check Elasticsearch connection
- Verify index pattern exists
- Confirm data is being ingested

### Missing Data
- Verify NiFi collectors are running
- Check PutElasticsearch processor status
- Confirm ingest pipelines are applied

### Slow Dashboard Performance
- Reduce time range
- Limit number of panels
- Check Elasticsearch query performance
- Consider data sampling for large time ranges

## Getting Help

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions
- Review [API-REFERENCE.md](API-REFERENCE.md) for LLM service details
- Open an issue: https://github.com/talentGitHub/ApacheNiFi/issues
- Email support: support@your-company.com

---

**Document Version**: 1.0.0  
**Last Updated**: 2026-01-28
