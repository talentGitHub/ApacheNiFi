# User Guide

Guide for using the Apache NiFi Observability Platform dashboards and features.

## Accessing Dashboards

Navigate to your Kibana instance and select "Dashboards" from the menu.

All NiFi dashboards are prefixed with `[NiFi]` for easy identification.

## Dashboard Overview

### 1. Executive Overview

**Purpose**: High-level system status for stakeholders and management

**Key Metrics**:
- **System Status**: Overall health indicator
- **Active Errors**: Error count in last 5 minutes
- **Queue Backpressure**: Highest queue utilization across all processors
- **JVM Memory**: Heap usage with threshold indicators
- **Error Rate**: Trend over time

**When to Use**:
- Daily status checks
- Executive reporting
- Incident triage
- Team standup meetings

**Recommended Refresh**: 30 seconds

### 2. Bulletin Deep Dive

**Purpose**: Detailed error analysis and troubleshooting

**Features**:
- Time series view of all bulletins by severity
- Top 10 most frequent error messages
- Error distribution by category
- Time-based pattern analysis
- Live bulletin stream with search

**When to Use**:
- Investigating specific errors
- Identifying error patterns
- Root cause analysis
- Post-incident reviews

**Pro Tips**:
- Use search bar to filter by component name
- Click on error categories to drill down
- Hover over heatmap to see hourly patterns
- Export data for offline analysis

### 3. System Diagnostics Health

**Purpose**: Monitor JVM, memory, CPU, and storage

**Key Panels**:
- Heap and Non-Heap gauges with thresholds
- Memory utilization timeline
- GC performance metrics
- Storage usage by repository
- CPU load and thread count

**When to Use**:
- Capacity planning
- Performance optimization
- Memory leak investigation
- Pre-deployment validation

**Warning Thresholds**:
- Heap > 85%: Warning
- Heap > 90%: Critical
- GC pause > 500ms: Warning
- Storage > 85%: Warning

### 4. Flow Performance Analytics

**Purpose**: Analyze processor throughput and identify bottlenecks

**Key Panels**:
- Throughput trends (bytes/sec, flowfiles/sec)
- Top processors by processing time
- Processor statistics table
- Queue backpressure monitoring
- Connection details

**When to Use**:
- Performance tuning
- Identifying slow processors
- Queue management
- Optimization planning

**Optimization Tips**:
- Processors with high avg processing time may need tuning
- High queue utilization indicates potential backpressure
- Compare throughput across environments

### 5. Multi-Environment Overview

**Purpose**: Compare metrics across dev, staging, and production

**Key Panels**:
- Environment health cards
- Throughput comparison
- Error rate comparison
- Resource utilization radar chart

**When to Use**:
- Cross-environment validation
- Deployment verification
- Consistency checks
- Resource allocation

### 6. Historical Trends & Capacity Planning

**Purpose**: Long-term analysis and forecasting

**Key Panels**:
- Data volume growth with ML forecast
- Storage growth projection
- Capacity projections table
- Processor duration distribution
- SLA compliance tracking

**When to Use**:
- Quarterly planning
- Budget forecasting
- Resource scaling decisions
- Trend analysis

**ML Forecast**:
- 30-day prediction with confidence intervals
- Updated hourly
- Based on last 90 days of data

### 7. Specific Error Analysis

**Purpose**: Deep dive into critical error patterns

**Focus Areas**:
- Port binding conflicts
- DistributedMapCacheServer failures
- Cascading failure patterns

**When to Use**:
- Investigating known issue types
- Pattern recognition
- Remediation verification

## Using ML Anomaly Detection

### Viewing Anomalies

1. Navigate to Kibana → Machine Learning → Anomaly Explorer
2. Select job: `nifi-processing-anomaly`, `nifi-queue-forecast`, or `nifi-error-spike`
3. Review anomaly timeline
4. Click on anomalies for details

### Understanding Severity

- **Critical** (score > 75): Immediate attention required
- **Major** (score 50-75): Investigation recommended
- **Minor** (score 25-50): Monitor
- **Info** (score < 25): Normal variation

### Forecasting

1. Open Queue Forecast job in ML app
2. Click "Forecast" button
3. Select forecast duration (up to 30 days)
4. Review prediction with confidence bounds

## Using LLM Analysis

### Analyzing an Error

```bash
# Get bulletin ID from Kibana (copy from bulletin stream)
BULLETIN_ID="480e958b-ec48-4890-a3be-b9154f963403"

# Call analysis service
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d "{\"bulletin_id\": \"$BULLETIN_ID\"}"
```

### Understanding Results

Response includes:
- **Root Cause**: What's causing the error
- **Immediate Actions**: Steps to resolve now
- **Prevention**: Long-term recommendations
- **Impact**: Business impact assessment
- **Confidence**: AI confidence score (0.0-1.0)

### Batch Analysis

Analyze multiple bulletins at once:

```bash
curl -X POST http://localhost:5000/analyze/batch \
  -H "Content-Type: application/json" \
  -d '{
    "bulletin_ids": ["id1", "id2", "id3"]
  }'
```

## Creating Custom Dashboards

1. Navigate to Kibana → Dashboards → Create dashboard
2. Add panels using existing visualizations
3. Use index patterns: `nifi-bulletins-*`, `nifi-system-diagnostics-*`, `nifi-flow-performance-*`
4. Save and share with team

## Setting Up Alerts

1. Navigate to Kibana → Stack Management → Rules and Connectors
2. Create rule with desired conditions
3. Configure notification channel
4. Test and enable

**Example: Critical Error Alert**

```
Condition: count of bulletins where bulletinLevel = "ERROR" > 10
Time window: last 5 minutes
Action: Send email to ops-team@company.com
```

## Best Practices

### Daily Routine

1. Check Executive Overview for system status
2. Review overnight errors in Bulletin Deep Dive
3. Verify ML anomalies in ML Explorer
4. Check capacity trends weekly

### During Incidents

1. Start with Executive Overview for quick status
2. Use Bulletin Deep Dive to identify error patterns
3. Check System Diagnostics for resource issues
4. Use Flow Performance to identify bottlenecks
5. Run LLM analysis for remediation guidance

### Performance Optimization

1. Use Flow Performance Analytics to identify slow processors
2. Review queue utilization for backpressure
3. Analyze historical trends for capacity planning
4. Compare environments to identify configuration issues

## Keyboard Shortcuts

- **Refresh**: `Ctrl+R`
- **Time picker**: `T`
- **Search**: `/`
- **Full screen**: `F`

## Exporting Data

1. Click "Share" in dashboard toolbar
2. Choose "CSV Reports" or "PNG/PDF"
3. Configure options
4. Download

## Mobile Access

Kibana dashboards are responsive and work on mobile devices:
- Use simplified views
- Reduce time range for faster loading
- Focus on KPI dashboards
