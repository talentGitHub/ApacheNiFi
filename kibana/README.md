# Kibana Dashboard Configurations

This directory contains Kibana dashboard configurations for Apache NiFi observability monitoring.

## Directory Structure

```
kibana/
├── dashboards/               # Dashboard JSON files (.ndjson format)
│   ├── nifi-executive-overview.ndjson
│   ├── nifi-bulletin-deep-dive.ndjson
│   ├── nifi-system-diagnostics-health.ndjson
│   ├── nifi-flow-performance-analytics.ndjson
│   ├── nifi-multi-environment-overview.ndjson
│   ├── nifi-historical-trends.ndjson
│   └── nifi-specific-error-analysis.ndjson
├── index-patterns/           # Index pattern/data view configurations
└── README.md                 # This file
```

## What's Included

### 7 Production-Ready Dashboards

1. **Executive Overview** (`nifi-executive-overview.ndjson`)
   - System status KPIs, active errors, JVM health, processor status
   - Auto-refresh: 30 seconds
   - Time range: Last 15 minutes

2. **Bulletin Deep Dive** (`nifi-bulletin-deep-dive.ndjson`)
   - Error timeline, top errors, error distribution, live bulletin stream
   - Time range: Last 1 hour

3. **System Diagnostics Health** (`nifi-system-diagnostics-health.ndjson`)
   - Heap/non-heap memory, GC performance, storage, CPU, threads
   - Auto-refresh: 1 minute
   - Time range: Last 4 hours

4. **Flow Performance Analytics** (`nifi-flow-performance-analytics.ndjson`)
   - Throughput trends, top processors, queue backpressure, connection details
   - Time range: Last 24 hours

5. **Multi-Environment Overview** (`nifi-multi-environment-overview.ndjson`)
   - Cross-environment health, throughput comparison, error rates
   - Auto-refresh: 1 minute
   - Time range: Last 1 hour

6. **Historical Trends & Capacity Planning** (`nifi-historical-trends.ndjson`)
   - Growth trends, ML forecasts, capacity projections, SLA compliance
   - Time range: Last 90 days

7. **Specific Error Analysis** (`nifi-specific-error-analysis.ndjson`)
   - Port binding errors, cache server failures, cascading failures
   - Time range: Last 7 days

## Quick Import

### Option 1: Automated Script (Recommended)

```bash
# From repository root
./scripts/setup-kibana.sh
```

This script will:
- Create all required index patterns
- Import all 7 dashboards
- Verify the import

### Option 2: Manual Import via Kibana UI

1. Open Kibana → **Stack Management** → **Saved Objects**
2. Click **Import**
3. Select all `.ndjson` files from `kibana/dashboards/`
4. Enable "Automatically overwrite conflicts"
5. Click **Import**

### Option 3: Using Kibana API

```bash
# Set your credentials
export KIBANA_URL="https://your-kibana.kb.cloud.elastic.io"
export API_KEY="your-api-key"

# Import a single dashboard
curl -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey ${API_KEY}" \
  --form file=@kibana/dashboards/nifi-executive-overview.ndjson

# Or loop through all dashboards
for dashboard in kibana/dashboards/*.ndjson; do
  echo "Importing $(basename $dashboard)..."
  curl -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -H "Authorization: ApiKey ${API_KEY}" \
    --form file=@"${dashboard}"
done
```

## Required Index Patterns

Before importing dashboards, ensure these index patterns exist:

| Index Pattern | Description | Required For |
|---------------|-------------|--------------|
| `nifi-bulletins-*` | NiFi error bulletins | Executive Overview, Bulletin Deep Dive, Specific Error Analysis |
| `nifi-system-diagnostics-*` | JVM and system metrics | System Diagnostics Health, Executive Overview |
| `nifi-flow-performance-*` | Flow and processor metrics | Flow Performance Analytics, Historical Trends |
| `nifi-ml-features-hourly` | ML aggregated features | Historical Trends |
| `nifi-ml-error-patterns` | ML error patterns | Specific Error Analysis |

Create these in Kibana via: **Stack Management** → **Data Views** → **Create data view**

## Dashboard Features

### Common Features Across All Dashboards

- **Time Range Picker**: Adjust the time window for data display
- **Auto-Refresh**: Configurable automatic dashboard refresh
- **Filters**: Add custom filters to narrow down data
- **Drill-Down**: Click on visualizations to explore detailed data
- **Export**: Export dashboard data to CSV or generate PDF reports
- **Share**: Share dashboard links or embed in applications

### Visualization Types Used

- **Line Charts**: Time-series trends
- **Bar Charts**: Comparative metrics
- **Pie Charts**: Distribution analysis
- **Gauges**: Single value metrics with thresholds
- **Tables**: Detailed data listings
- **Heatmaps**: Time-based pattern analysis
- **Sankey Diagrams**: Flow and relationship visualization

## Customization

### Modifying Dashboards

1. Open dashboard in Kibana
2. Click **Edit** button (top-right)
3. Modify panels:
   - Click gear icon on panel → **Edit lens/visualization**
   - Adjust queries, aggregations, colors, etc.
4. Save changes

### Cloning Dashboards

To create custom variations:

1. Open dashboard
2. Click **Share** → **Copy to space**
3. Or export via **Stack Management** → **Saved Objects** → Export
4. Re-import with new name

### Adding Custom Panels

1. Edit dashboard
2. Click **Create visualization**
3. Choose visualization type (Lens recommended)
4. Configure data source and metrics
5. Save and add to dashboard

## Version Compatibility

- **Kibana Version**: 8.x (tested on 8.11+)
- **Dashboard Format**: NDJSON (Newline Delimited JSON)
- **Migration**: Dashboards auto-migrate to newer Kibana versions
- **Backward Compatibility**: May work on Kibana 7.17+ with manual adjustments

## File Format

Each `.ndjson` file contains:

```json
{
  "attributes": {
    "title": "Dashboard Name",
    "description": "Dashboard description",
    "panelsJSON": "[...]",  // Panel layout and configuration
    "optionsJSON": "{...}",  // Dashboard-level options
    "timeFrom": "now-15m",   // Default time range start
    "timeTo": "now",         // Default time range end
    "refreshInterval": {...} // Auto-refresh settings
  },
  "id": "dashboard-id",
  "references": [...],       // Index pattern references
  "type": "dashboard"
}
```

## Exporting Dashboards

To backup or share your customized dashboards:

```bash
# Export all dashboards
cd kibana/dashboards
curl -X POST "${KIBANA_URL}/api/saved_objects/_export" \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "dashboard",
    "search": "NiFi"
  }' > nifi-dashboards-backup.ndjson

# Export specific dashboard
curl -X POST "${KIBANA_URL}/api/saved_objects/_export" \
  -H "kbn-xsrf: true" \
  -H "Authorization: ApiKey ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "objects": [
      {"type": "dashboard", "id": "nifi-executive-overview"}
    ]
  }' > nifi-executive-overview-backup.ndjson
```

## Troubleshooting

### Import Fails: "Index pattern not found"

**Solution**: Create index patterns first before importing dashboards.

### Dashboards Show "No Data"

**Solutions**:
1. Expand time range (try "Last 30 days")
2. Verify data exists in Elasticsearch indices
3. Check index pattern field mappings

### Visualization Errors

**Solution**: Re-create index patterns to refresh field mappings.

## Documentation

For detailed setup and usage instructions:

- **Quick Start**: [../docs/KIBANA-QUICK-START.md](../docs/KIBANA-QUICK-START.md)
- **Complete Guide**: [../docs/KIBANA-SETUP-GUIDE.md](../docs/KIBANA-SETUP-GUIDE.md)
- **Main README**: [../README.md](../README.md)

## Support

- **Issues**: https://github.com/talentGitHub/ApacheNiFi/issues
- **Discussions**: https://github.com/talentGitHub/ApacheNiFi/discussions
- **Community**: GitHub Discussions for questions and support

## License

These dashboard configurations are part of the Apache NiFi Observability Platform and are provided under the MIT License.

---

**Last Updated**: 2026-01-29  
**Dashboard Version**: 1.0.0  
**Compatible with**: Kibana 8.x
