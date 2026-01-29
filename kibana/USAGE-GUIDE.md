# System Health Dashboard - Usage Guide

## Overview

The System Health Dashboard provides real-time monitoring of Apache NiFi's JVM and OS-level health metrics. This guide will help you understand, import, and use the dashboard effectively.

## Dashboard Components

### 1. Heap Memory Usage (%) Gauge

**Location**: Top-left panel  
**Purpose**: Real-time heap memory utilization monitoring

**Visual Indicators**:
- 🟢 **Green (0-50%)**: Normal operation - heap usage is healthy
- 🟡 **Yellow (51-80%)**: Moderate usage - monitor for trends
- 🔴 **Red (81-100%)**: Critical - immediate attention required

**What to Monitor**:
- Consistently high values (>80%) may indicate:
  - Memory leaks
  - Insufficient heap allocation
  - Need for JVM tuning
- Frequent spikes suggest:
  - Large flowfile processing
  - Inadequate GC configuration

**Recommended Actions**:
- **Green Zone**: Continue normal operations
- **Yellow Zone**: Review flowfile sizes, consider heap increase
- **Red Zone**: 
  1. Check for memory leaks
  2. Review bulletin logs for OOM warnings
  3. Consider increasing heap size in `bootstrap.conf`

### 2. Heap Usage Trend (Time Series)

**Location**: Top-right panel  
**Purpose**: Historical heap memory consumption analysis

**Key Features**:
- Time-series visualization of average heap usage
- Red reference line at 85% of max heap
- Helps identify usage patterns and growth trends

**What to Monitor**:
- **Upward trends**: Potential memory leak or increasing load
- **Sustained high usage**: Need for heap expansion
- **Frequent crossings of 85% line**: Risk of OOM events

**Analysis Tips**:
1. Compare with GC pause times
2. Correlate with throughput changes
3. Identify time-of-day patterns

### 3. GC Pause Time (Bar Chart)

**Location**: Bottom-left panel  
**Purpose**: Garbage collection performance monitoring by site

**Metrics Displayed**:
- Average GC pause time in milliseconds
- Breakdown by site (top 3 sites shown)
- Time-series with 5-minute intervals

**What to Monitor**:
- **Healthy**: < 100ms average pause time
- **Warning**: 100-500ms - review GC algorithm
- **Critical**: > 500ms - significant performance impact

**Common Issues**:
- Long pause times indicate:
  - Inadequate heap size
  - Need for G1GC or other low-latency collectors
  - Memory fragmentation

**Tuning Recommendations**:
```bash
# For NiFi 1.x, update bootstrap.conf:

# G1GC (recommended for large heaps)
java.arg.13=-XX:+UseG1GC
java.arg.14=-XX:MaxGCPauseMillis=200

# For smaller heaps, consider CMS
java.arg.13=-XX:+UseConcMarkSweepGC
java.arg.14=-XX:+CMSClassUnloadingEnabled
```

### 4. Processor Load Average (Line Chart)

**Location**: Bottom-right panel  
**Purpose**: CPU load monitoring across sites

**Metrics Displayed**:
- Average processor load (system load average)
- Per-site breakdown with top 3 sites
- 1-minute intervals for real-time monitoring

**What to Monitor**:
- **Normal**: Load < number of CPU cores
- **Warning**: Load = 1.5x CPU cores
- **Critical**: Load > 2x CPU cores

**Correlation Analysis**:
Combine with:
- Active thread counts
- Processor scheduling
- Flowfile queue depths

## Quick Start

### Step 1: Prerequisites

Before using the dashboard, ensure:

1. **Elasticsearch Index**:
   ```bash
   # Verify index exists
   curl -X GET "https://your-es-instance.es.cloud/_cat/indices/nifi-diag*?v"
   ```

2. **Index Pattern**:
   - Navigate to Kibana → Stack Management → Index Patterns
   - Create `nifi-diag*` pattern with `@timestamp` time field

3. **Data Fields**:
   Required fields in your documents:
   ```json
   {
     "@timestamp": "2026-01-29T06:00:00.000Z",
     "site": "production-site-1",
     "systemDiagnostics": {
       "aggregateSnapshot": {
         "usedHeapBytes": 4294967296,
         "maxHeapBytes": 8589934592,
         "processorLoadAverage": 2.5,
         "garbageCollection": {
           "collectionMillis": 125
         }
       }
     }
   }
   ```

### Step 2: Import the Dashboard

**Option A: Using the Import Script**

```bash
# Navigate to repository
cd /path/to/ApacheNiFi

# Configure environment
export KIBANA_URL="https://your-kibana.kb.cloud"

# Run import script (will prompt for credentials)
./kibana/import-dashboard.sh
```

**Option B: Manual Import via UI**

1. Log in to Kibana
2. Go to **Stack Management** → **Saved Objects**
3. Click **Import**
4. Upload `kibana/dashboards/system-health-dashboard.ndjson`
5. Handle any conflicts (recommend "Automatically overwrite")

### Step 3: Access the Dashboard

1. Navigate to Kibana → **Dashboard**
2. Search for "System Health Dashboard"
3. Click to open

### Step 4: Configure Time Range

1. Click time picker (top-right)
2. Select range (e.g., Last 24 hours, Last 7 days)
3. Enable auto-refresh (e.g., every 30 seconds)

## Common Use Cases

### 1. Real-Time Health Monitoring

**Scenario**: Monitor NiFi during peak hours

**Configuration**:
- Time range: Last 15 minutes
- Refresh: Every 30 seconds
- Focus: Heap gauge and GC pause times

**Actions**:
- Watch for yellow/red heap gauge
- Monitor GC spikes
- Check processor load trends

### 2. Capacity Planning

**Scenario**: Determine if heap expansion is needed

**Configuration**:
- Time range: Last 30 days
- Refresh: None (static analysis)
- Focus: Heap usage trend

**Analysis**:
1. Identify average usage level
2. Check for upward trends
3. Calculate headroom (distance to 85% line)
4. Plan expansion if consistently >70%

### 3. Performance Troubleshooting

**Scenario**: Investigate slowness or timeouts

**Configuration**:
- Time range: Last 1 hour (around incident time)
- Refresh: Manual
- Focus: All panels

**Investigation Steps**:
1. Check heap usage during incident
2. Correlate with GC pause times
3. Review processor load
4. Cross-reference with bulletin logs

### 4. Multi-Site Comparison

**Scenario**: Compare health across environments

**Configuration**:
- Time range: Last 24 hours
- Refresh: Every 5 minutes
- Focus: GC pause and processor load

**Comparison**:
1. Identify site-specific issues
2. Compare load distribution
3. Detect anomalies in specific sites

## Advanced Configuration

### Customizing Thresholds

Edit the dashboard JSON to adjust gauge thresholds:

```json
"gauge_color_rules": [
  {"value": 0, "gauge": "rgba(0,191,179,1)", "operator": "gte"},
  {"value": 60, "gauge": "rgba(245,166,35,1)", "operator": "gte"},
  {"value": 90, "gauge": "rgba(235,12,12,1)", "operator": "gte"}
]
```

### Adding Additional Metrics

To extend the dashboard:

1. **Clone existing panel**:
   - Click panel menu → More → Clone panel

2. **Edit visualization**:
   - Click panel menu → Edit lens (or Edit visualization)
   - Modify field selections
   - Update aggregations

3. **Save changes**:
   - Click **Save and return**

### Filtering by Site

Use Kibana filters for site-specific views:

1. Click **Add filter** at the top
2. Field: `site`
3. Operator: `is`
4. Value: Your site name (e.g., `production-site-1`)
5. Click **Save**

## Troubleshooting

### Dashboard Shows "No Results"

**Possible Causes**:
1. Time range doesn't match your data
2. Index pattern mismatch
3. No data in Elasticsearch

**Solutions**:
```bash
# Check data exists
curl -X GET "https://your-es-instance.es.cloud/nifi-diag*/_search?size=1"

# Verify time range
# Click time picker → Adjust range to cover your data

# Refresh index pattern
# Stack Management → Index Patterns → Refresh field list
```

### Visualizations Show Errors

**Error**: "Field not found"

**Solution**:
- Verify field names match your data schema
- Update field references in visualization configuration

**Error**: "Index pattern not found"

**Solution**:
1. Check index pattern exists
2. Update dashboard references if using different ID

### Performance Issues

**Symptom**: Dashboard loads slowly

**Optimizations**:
1. Reduce time range (e.g., from 30 days to 7 days)
2. Increase aggregation intervals
3. Disable auto-refresh during analysis

## Integration with Alerting

Create alerts based on dashboard metrics:

### Example: High Heap Alert

1. Go to **Stack Management** → **Rules**
2. Click **Create rule**
3. Select **Elasticsearch query**
4. Configure:
   ```json
   {
     "index": "nifi-diag*",
     "query": {
       "bool": {
         "must": [
           {
             "script": {
               "script": {
                 "source": "doc['systemDiagnostics.aggregateSnapshot.usedHeapBytes'].value / doc['systemDiagnostics.aggregateSnapshot.maxHeapBytes'].value > 0.85"
               }
             }
           }
         ]
       }
     }
   }
   ```
5. Set threshold: Count above 3 (consecutive violations)
6. Add action: Email, Slack, PagerDuty, etc.

## Best Practices

### 1. Regular Review Schedule

- **Daily**: Quick check during business hours
- **Weekly**: Review trends and capacity
- **Monthly**: Capacity planning and optimization

### 2. Baseline Establishment

- Record normal operating ranges
- Document typical GC behavior
- Note expected processor loads

### 3. Correlation Analysis

Always correlate dashboard metrics with:
- Application logs
- NiFi bulletin logs
- External monitoring (APM tools)
- Business events (batch jobs, peak traffic)

### 4. Team Training

Ensure team members understand:
- What each metric means
- When to escalate
- How to investigate issues
- Where to find additional context

## Support and Resources

- **Dashboard Issues**: [GitHub Issues](https://github.com/talentGitHub/ApacheNiFi/issues)
- **NiFi Documentation**: [Apache NiFi Docs](https://nifi.apache.org/docs.html)
- **Elasticsearch Guide**: [Elastic Docs](https://www.elastic.co/guide/)

## Changelog

### Version 1.0.0 (2026-01-29)
- Initial dashboard release
- 4 core visualizations
- Support for Kibana 8.x
- Multi-site monitoring

---

**Last Updated**: 2026-01-29  
**Kibana Version**: 8.x  
**Maintained By**: Platform Engineering Team
