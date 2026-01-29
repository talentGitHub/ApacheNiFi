# Kibana Dashboard Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the 7 production-ready Kibana dashboards for Apache NiFi observability. These dashboards provide comprehensive monitoring across errors, system health, flow performance, and capacity planning.

## Prerequisites

Before setting up Kibana dashboards, ensure you have:

1. **Elasticsearch Cloud 8.x** deployment running
2. **Kibana 8.x** access with admin privileges
3. **Apache NiFi** data flowing into Elasticsearch (see main README for NiFi setup)
4. **Index patterns** created for:
   - `nifi-bulletins-*`
   - `nifi-system-diagnostics-*`
   - `nifi-flow-performance-*`
   - `nifi-ml-features-hourly`
   - `nifi-ml-error-patterns`

## Quick Setup (Automated)

### Option 1: Using the Setup Script

The easiest way to import all dashboards is using our automated script:

```bash
# Navigate to the repository root
cd /path/to/ApacheNiFi

# Run the setup script
./scripts/setup-kibana.sh

# The script will prompt for:
# - Kibana URL (e.g., https://your-deployment.kb.cloud.elastic.io)
# - API Key or Username/Password
# - Elasticsearch endpoint (optional, for index pattern verification)
```

The script will:
- ✅ Verify Kibana connectivity
- ✅ Check required indices exist
- ✅ Create/update index patterns and data views
- ✅ Import all 7 dashboards
- ✅ Set up default time ranges
- ✅ Validate dashboard imports

### Option 2: Using Kibana UI (Manual Import)

If you prefer manual control or the script doesn't work:

1. **Navigate to Kibana**
   - Open your Kibana instance: `https://your-kibana.kb.cloud.elastic.io`
   - Log in with admin credentials

2. **Create Index Patterns First**
   - Go to **Stack Management** → **Index Patterns** (or **Data Views** in 8.x+)
   - Follow the steps in section "Creating Index Patterns" below

3. **Import Dashboards**
   - Go to **Stack Management** → **Saved Objects**
   - Click **Import**
   - Select dashboard files from `kibana/dashboards/` directory
   - Import in this order:
     1. `nifi-executive-overview.ndjson`
     2. `nifi-bulletin-deep-dive.ndjson`
     3. `nifi-system-diagnostics-health.ndjson`
     4. `nifi-flow-performance-analytics.ndjson`
     5. `nifi-multi-environment-overview.ndjson`
     6. `nifi-historical-trends.ndjson`
     7. `nifi-specific-error-analysis.ndjson`

4. **Resolve Conflicts** (if prompted)
   - Choose **Overwrite** for existing objects
   - Or **Skip** to keep existing configurations

5. **Verify Import**
   - Go to **Analytics** → **Dashboard**
   - You should see all 7 NiFi dashboards listed

## Detailed Manual Setup

### Step 1: Creating Index Patterns

Index patterns (called "Data Views" in Kibana 8.x+) tell Kibana which Elasticsearch indices to query.

#### 1.1 Create Bulletins Index Pattern

1. Navigate to **Stack Management** → **Data Views** (or **Index Patterns**)
2. Click **Create data view**
3. Configure:
   - **Name**: `NiFi Bulletins`
   - **Index pattern**: `nifi-bulletins-*`
   - **Time field**: `@timestamp`
4. Click **Save data view**

#### 1.2 Create System Diagnostics Index Pattern

1. Click **Create data view** again
2. Configure:
   - **Name**: `NiFi System Diagnostics`
   - **Index pattern**: `nifi-system-diagnostics-*`
   - **Time field**: `@timestamp`
3. Click **Save data view**

#### 1.3 Create Flow Performance Index Pattern

1. Click **Create data view**
2. Configure:
   - **Name**: `NiFi Flow Performance`
   - **Index pattern**: `nifi-flow-performance-*`
   - **Time field**: `@timestamp`
3. Click **Save data view**

#### 1.4 Create ML Features Index Pattern

1. Click **Create data view**
2. Configure:
   - **Name**: `NiFi ML Features Hourly`
   - **Index pattern**: `nifi-ml-features-hourly`
   - **Time field**: `@timestamp`
3. Click **Save data view**

#### 1.5 Create ML Error Patterns Index Pattern

1. Click **Create data view**
2. Configure:
   - **Name**: `NiFi ML Error Patterns`
   - **Index pattern**: `nifi-ml-error-patterns`
   - **Time field**: `@timestamp`
3. Click **Save data view**

### Step 2: Verify Index Patterns

After creating index patterns:

1. Go to **Discover**
2. Select each data view from the dropdown
3. Verify you see data appearing
4. Check the time range picker - adjust if no data appears

**Troubleshooting**: If no data appears:
- Verify NiFi is sending data to Elasticsearch
- Check index names match the patterns
- Ensure time range includes when data was sent
- Verify Elasticsearch index templates were deployed

### Step 3: Import Dashboard JSON Files

#### Method A: Bulk Import via Saved Objects

1. Navigate to **Stack Management** → **Saved Objects**
2. Click **Import** button (top-right)
3. Select dashboard file(s) from your local `kibana/dashboards/` directory
4. Options to configure:
   - **Check for existing objects**: Enabled (recommended)
   - **Automatically overwrite conflicts**: Enable if updating existing dashboards
5. Click **Import**
6. Review the import summary
7. Click **Done**

#### Method B: Import Individual Dashboards

For each dashboard JSON file:

1. Go to **Stack Management** → **Saved Objects**
2. Click **Import**
3. Select one `.ndjson` file
4. Click **Import**
5. If index pattern IDs don't match, use **Index Pattern Conflicts** resolution
6. Repeat for all 7 dashboards

### Step 4: Configure Dashboard Settings

After importing dashboards, customize settings:

#### 4.1 Set Default Time Ranges

For real-time monitoring dashboards:

1. Open **Executive Overview** dashboard
2. Set time range to **Last 15 minutes**
3. Enable **Auto-refresh** → **30 seconds**
4. Click the save icon
5. Check "Store time with dashboard"

Recommended time ranges:
- **Executive Overview**: Last 15 minutes, auto-refresh 30s
- **Bulletin Deep Dive**: Last 1 hour
- **System Diagnostics Health**: Last 4 hours, auto-refresh 1m
- **Flow Performance Analytics**: Last 24 hours
- **Multi-Environment Overview**: Last 1 hour, auto-refresh 1m
- **Historical Trends**: Last 90 days
- **Specific Error Analysis**: Last 7 days

#### 4.2 Configure Dashboard Filters

Some dashboards support environment filtering:

1. Open **Multi-Environment Overview**
2. Click **Add filter**
3. Configure:
   - **Field**: `nifi.environment`
   - **Operator**: `is one of`
   - **Value**: (select your environments)
4. Click **Pin across all apps** to make filter persistent

### Step 5: Set Up Dashboard Links

Create a navigation menu for easy dashboard access:

1. Go to **Stack Management** → **Advanced Settings**
2. Search for "defaultRoute"
3. Set to: `/app/dashboards#/view/nifi-executive-overview`
4. This makes Executive Overview the landing page

### Step 6: Configure Access Controls (Optional)

If using Kibana Spaces for multi-tenancy:

1. Go to **Stack Management** → **Spaces**
2. Create a space: **NiFi Monitoring**
3. Copy all NiFi dashboards to this space:
   - Go to **Saved Objects**
   - Select all NiFi dashboards
   - Click **Copy to space**
   - Select **NiFi Monitoring**
4. Assign roles:
   - Go to **Stack Management** → **Roles**
   - Create role with Kibana privileges for the space

## Dashboard Descriptions

### 1. Executive Overview
**Purpose**: High-level system status for stakeholders and NOC  
**Refresh**: 30 seconds  
**Key Metrics**:
- System status (Healthy/Warning/Critical)
- Active error count (last 5 minutes)
- JVM heap utilization with thresholds
- Current error rate trend
- Queue backpressure gauge
- Processor health heatmap (by status)

**Use Cases**:
- NOC monitoring wall display
- Quick health checks
- Executive reporting
- SLA monitoring

**Access**: `#/view/nifi-executive-overview`

### 2. Bulletin Deep Dive
**Purpose**: Detailed error analysis and troubleshooting  
**Key Visualizations**:
- Bulletins timeline (stacked by severity: ERROR/WARN/INFO)
- Top 10 error messages with counts
- Error distribution pie chart
- Time-of-day heatmap (identifies patterns)
- Live bulletin table with search/filter
- Error sources breakdown

**Use Cases**:
- Troubleshooting specific errors
- Identifying recurring issues
- Root cause analysis
- Trend analysis

**Access**: `#/view/nifi-bulletin-deep-dive`

### 3. System Diagnostics Health
**Purpose**: Deep JVM, memory, storage, and GC monitoring  
**Key Visualizations**:
- Heap memory gauge (used vs. max)
- Non-heap memory gauge
- GC count rate (collections per minute)
- GC duration average
- Storage utilization by repository (content, flowfile, provenance)
- CPU load average
- Thread count trends
- Historical comparison table

**Use Cases**:
- Performance tuning
- Capacity planning
- Memory leak detection
- GC optimization

**Access**: `#/view/nifi-system-diagnostics-health`

### 4. Flow Performance Analytics
**Purpose**: Processor and connection performance optimization  
**Key Visualizations**:
- Throughput rates (bytes read/written/transferred)
- Top 10 processors by processing time
- Processor statistics detailed table
- Queue backpressure by connection
- Connection details (queued, data size)
- Records processed trends
- Processor duration distribution histogram

**Use Cases**:
- Performance optimization
- Bottleneck identification
- Flow tuning
- SLA validation

**Access**: `#/view/nifi-flow-performance-analytics`

### 5. Multi-Environment Overview
**Purpose**: Cross-environment comparative monitoring  
**Key Visualizations**:
- Environment health status cards
- Throughput comparison chart (by environment)
- Error rate comparison
- Resource utilization radar chart
- Environment-specific KPIs

**Use Cases**:
- Dev/Stage/Prod comparison
- Multi-datacenter monitoring
- Regional performance comparison
- Environment-specific troubleshooting

**Filters**: Use `nifi.environment` field  
**Access**: `#/view/nifi-multi-environment-overview`

### 6. Historical Trends & Capacity Planning
**Purpose**: Long-term analysis and ML-powered forecasting  
**Key Visualizations**:
- Data processing volume growth (30-day forecast via ML)
- Storage growth projection
- Capacity threshold warnings
- Processor duration percentiles (P50, P90, P99)
- SLA compliance gauge (target: 99.9% uptime)
- Resource trend predictions

**ML Integration**:
- Uses `nifi-ml-features-hourly` transform data
- Forecasting via Elasticsearch ML jobs

**Use Cases**:
- Capacity planning
- Budget forecasting
- SLA reporting
- Growth trend analysis

**Access**: `#/view/nifi-historical-trends`

### 7. Specific Error Analysis
**Purpose**: Deep dive into critical error patterns  
**Focused Error Types**:
- Port binding failures ("Address already in use")
- DistributedMapCacheServer errors
- Controller service failures
- Cascading failure chains (Sankey diagram)

**Key Visualizations**:
- Error occurrence timeline
- Port conflict details table
- Service dependency map
- Error correlation matrix
- Root cause indicators

**Use Cases**:
- Incident investigation
- Root cause analysis
- Service dependency troubleshooting
- Failure pattern recognition

**Access**: `#/view/nifi-specific-error-analysis`

## Customization Guide

### Adding Custom Visualizations

1. Open any dashboard in **Edit** mode
2. Click **Create visualization**
3. Select visualization type:
   - **Lens**: Modern, recommended for most use cases
   - **TSVB**: Time series with advanced functions
   - **Vega/Vega-Lite**: Custom chart specifications
4. Configure data source (index pattern)
5. Configure metrics and dimensions
6. Add to dashboard

### Modifying Existing Panels

1. Open dashboard in **Edit** mode
2. Hover over panel, click the **gear icon**
3. Select **Edit lens** (or respective editor)
4. Modify queries, aggregations, or styling
5. Click **Save** and return to dashboard
6. Save dashboard changes

### Creating Custom Filters

1. Click **Add filter** on dashboard
2. Select **Edit as Query DSL** for advanced filtering
3. Example: Filter for specific processor types
```json
{
  "match": {
    "componentType": "Processor"
  }
}
```
4. Apply and save filter

### Cloning Dashboards

To create environment-specific variations:

1. Open the dashboard
2. Click **Share** → **CSV Reports** → **Copy POST URL** (to get dashboard ID)
3. Go to **Stack Management** → **Saved Objects**
4. Find the dashboard
5. Click export icon
6. Re-import with new name
7. Modify filters for specific environment

## Troubleshooting

### Issue: Dashboard Shows "No Data"

**Causes & Solutions**:

1. **Time range too narrow**
   - Expand time range to last 7 or 30 days
   - Check when data was last sent from NiFi

2. **Index pattern mismatch**
   - Verify index names: `GET /_cat/indices/nifi-*`
   - Ensure patterns match (e.g., `nifi-bulletins-2026.01.29`)

3. **No data in Elasticsearch**
   - Check NiFi is running and sending data
   - Verify InvokeHTTP/PutElasticsearchRecord processors
   - Check NiFi bulletin board for errors

4. **Field mapping issues**
   - Go to **Stack Management** → **Index Management**
   - Check field mappings match dashboard expectations

### Issue: Visualizations Show Errors

**Error**: "Field 'heapUtilization' not found"

**Solution**:
- Index template not applied correctly
- Verify field exists: **Discover** → select index → check fields
- Re-deploy Elasticsearch index templates

**Error**: "Unauthorized" or "403 Forbidden"

**Solution**:
- Check Kibana user has required privileges
- Minimum required: `read` on `nifi-*` indices
- Dashboard editing requires: `all` on `.kibana*`

### Issue: Dashboard Import Fails

**Error**: "Index pattern not found"

**Solution**:
1. Import index patterns first (use `kibana/index-patterns/` files)
2. Or create index patterns manually (see Step 1)
3. Then retry dashboard import

**Error**: "Conflict: object already exists"

**Solution**:
- Enable "Automatically overwrite conflicts" during import
- Or delete existing dashboards first via **Saved Objects**

### Issue: Dashboards Load Slowly

**Causes & Solutions**:

1. **Large time range**
   - Reduce to last 24 hours for real-time dashboards
   - Use Summary index patterns for historical data

2. **Too many visualizations**
   - Split into multiple dashboards
   - Remove unused panels

3. **Unoptimized queries**
   - Add index-level filters
   - Use aggregations instead of document queries
   - Enable caching in Kibana settings

4. **Elasticsearch performance**
   - Check cluster health: `GET /_cluster/health`
   - Increase shard allocation
   - Add more data nodes

### Issue: ML Forecasts Not Showing

**Requirements**:
- Elasticsearch ML license (Basic or higher)
- ML jobs must be running
- Sufficient historical data (minimum 2 weeks for forecasting)

**Solution**:
1. Verify ML jobs: **Machine Learning** → **Jobs**
2. Check jobs status: `nifi-queue-forecast` should be "opened"
3. Start job if stopped: **Actions** → **Start datafeed**
4. Wait for bucket span intervals (1 hour for queue forecast)

## Advanced Configuration

### Setting Up Alerts from Dashboards

1. Open dashboard
2. Click panel menu (three dots)
3. Select **More** → **Create alert rule**
4. Configure:
   - **Threshold**: e.g., heap > 85%
   - **Time window**: 5 minutes
   - **Actions**: Slack, email, webhook
5. Save rule

### Embedding Dashboards

To embed in external applications:

1. Open dashboard
2. Click **Share** → **Embed code**
3. Copy iframe code or generate snapshot URL
4. Configure authentication:
   - Use reporting user with read-only access
   - Or generate anonymous access link (if enabled)

### Exporting Dashboards

To backup or share dashboard configurations:

1. Go to **Stack Management** → **Saved Objects**
2. Select dashboards to export
3. Click **Export** → **Export X objects**
4. Save `.ndjson` file
5. Store in version control

### Dashboard API Usage

Automate dashboard operations via Kibana API:

```bash
# List all dashboards
curl -X GET "https://your-kibana.kb.cloud.elastic.io/api/saved_objects/_find?type=dashboard" \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey YOUR_API_KEY"

# Import dashboard
curl -X POST "https://your-kibana.kb.cloud.elastic.io/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey YOUR_API_KEY" \
  -F file=@nifi-executive-overview.ndjson
```

## Maintenance

### Regular Tasks

**Daily**:
- Check dashboard load times
- Verify real-time data flow
- Review alert notifications

**Weekly**:
- Review and remove old snapshots
- Check Elasticsearch disk usage
- Validate ML job performance

**Monthly**:
- Update dashboard queries for optimizations
- Review and archive old dashboards
- Update index lifecycle policies

### Updating Dashboards

When new versions are released:

1. Backup existing dashboards (export to `.ndjson`)
2. Import new dashboard files
3. Choose "Overwrite" when prompted
4. Test each dashboard
5. Revert from backup if issues occur

## Best Practices

### Performance Optimization

1. **Use appropriate time ranges**
   - Real-time: last 15-30 minutes
   - Analysis: last 7 days
   - Historical: last 90 days with summaries

2. **Limit visualizations per dashboard**
   - Maximum 12-15 panels per dashboard
   - Use drill-down instead of cramming data

3. **Use date histogram intervals wisely**
   - Real-time: 10-30 second intervals
   - Hourly: 1-minute intervals
   - Daily: 1-hour intervals
   - Historical: daily intervals

4. **Enable query caching**
   - Set cache timeout in Kibana Advanced Settings
   - Use data view caching for frequently accessed fields

### Security Best Practices

1. **Use read-only users for dashboards**
   - Create dedicated dashboard viewers role
   - Restrict access to sensitive data

2. **Enable audit logging**
   - Track who views dashboards
   - Monitor for suspicious activity

3. **Use Spaces for multi-tenancy**
   - Separate dashboards by team/environment
   - Prevent accidental modifications

4. **Regular access reviews**
   - Audit user permissions quarterly
   - Remove inactive users

## Reference Materials

### Key Fields by Index

**nifi-bulletins-***:
- `@timestamp`: Event time
- `bulletinLevel`: ERROR, WARN, INFO
- `bulletinMessage`: Error message text
- `bulletinSourceName`: Component name
- `bulletinSourceType`: Component type
- `bulletinCategory`: Error category
- `nifi.environment`: Environment name

**nifi-system-diagnostics-***:
- `@timestamp`: Collection time
- `heapUtilization`: Percentage (0-100)
- `usedHeapBytes`: Bytes
- `maxHeapBytes`: Bytes
- `processorLoadAverage`: System CPU load
- `totalThreads`: JVM thread count
- `gcCount`: GC collection count
- `storageUsage`: Storage by repository type

**nifi-flow-performance-***:
- `@timestamp`: Collection time
- `componentName`: Processor name
- `processorType`: Processor class
- `runStatus`: RUNNING, STOPPED, INVALID
- `bytesRead`: Bytes
- `bytesWritten`: Bytes
- `processingNanos`: Nanoseconds
- `queuedCount`: Queued flowfiles

### Index Pattern IDs

If you need to manually reference index patterns in dashboard JSON:

- `nifi-bulletins-*`: Pattern for bulletin indices
- `nifi-system-diagnostics-*`: Pattern for system metrics
- `nifi-flow-performance-*`: Pattern for flow data
- `nifi-ml-features-hourly`: ML aggregated data
- `nifi-ml-error-patterns`: ML error analysis

### Query DSL Examples

**Filter for errors only**:
```json
{
  "query": {
    "term": {
      "bulletinLevel": "ERROR"
    }
  }
}
```

**Filter for specific processor**:
```json
{
  "query": {
    "match": {
      "bulletinSourceName": "InvokeHTTP"
    }
  }
}
```

**Aggregate errors by category**:
```json
{
  "aggs": {
    "error_categories": {
      "terms": {
        "field": "bulletinCategory.keyword",
        "size": 10
      }
    }
  }
}
```

## Getting Help

### Common Resources

- **Elastic Documentation**: https://www.elastic.co/guide/en/kibana/8.x/index.html
- **Community Forum**: https://discuss.elastic.co/c/kibana
- **GitHub Issues**: https://github.com/talentGitHub/ApacheNiFi/issues

### Support Channels

1. **Create a GitHub Issue**: For bugs or feature requests
2. **Discussion Forum**: For questions and best practices
3. **Email Support**: support@your-company.com

### Frequently Asked Questions

**Q: Can I use these dashboards with on-premise Elasticsearch?**  
A: Yes, these dashboards are compatible with Elasticsearch/Kibana 8.x (self-hosted or cloud).

**Q: Do I need an Elastic license for ML features?**  
A: Basic features work with the free Basic license. Advanced ML features require a subscription.

**Q: Can I modify the dashboards?**  
A: Yes! Dashboards are fully customizable. We recommend cloning before major modifications.

**Q: How do I add more environments?**  
A: Add an `nifi.environment` field to your data, then filter dashboards by this field.

**Q: What if my NiFi version is different?**  
A: Dashboards work with NiFi 1.15+. Field names may vary in older versions; adjust index patterns accordingly.

## Appendix

### Dashboard File Structure

Each `.ndjson` file contains:
- Dashboard configuration (layout, panels)
- Visualization definitions (queries, aggregations)
- References to index patterns
- Saved searches (if applicable)

### Validation Checklist

After setup, verify:

- [ ] All 7 dashboards appear in Dashboard list
- [ ] Each dashboard displays data (no "No data" errors)
- [ ] Time range selectors work correctly
- [ ] Auto-refresh functions properly (if enabled)
- [ ] Filters apply correctly
- [ ] Drill-down links work
- [ ] Export functionality works
- [ ] Share/embed features accessible

### Version Compatibility Matrix

| NiFi Version | Elasticsearch | Kibana | Status |
|--------------|---------------|--------|--------|
| 1.23.x       | 8.11+         | 8.11+  | ✅ Tested |
| 1.22.x       | 8.10+         | 8.10+  | ✅ Compatible |
| 1.21.x       | 8.8+          | 8.8+   | ✅ Compatible |
| 1.20.x       | 8.6+          | 8.6+   | ⚠️ Limited testing |
| < 1.20       | 7.17+         | 7.17+  | ⚠️ May require modifications |

---

**Document Version**: 1.0.0  
**Last Updated**: 2026-01-29  
**Maintained by**: Platform Engineering Team
