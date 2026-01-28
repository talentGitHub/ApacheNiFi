# Kibana Dashboards

This directory contains 7 pre-configured Kibana dashboards for Apache NiFi observability.

## Available Dashboards

1. **nifi-executive-overview.ndjson** - Executive Overview Dashboard
   - Single-pane-of-glass for stakeholders
   - System status KPIs
   - Active errors and memory utilization
   - Refresh: 30 seconds

2. **nifi-bulletin-deep-dive.ndjson** - Bulletin Deep Dive Dashboard
   - Comprehensive error analysis
   - Error distribution and patterns
   - Live bulletin stream with search

3. **nifi-system-diagnostics.ndjson** - System Diagnostics Health Dashboard
   - JVM memory monitoring
   - GC performance metrics
   - Storage utilization by repository

4. **nifi-flow-performance.ndjson** - Flow Performance Analytics Dashboard
   - Throughput trends and rates
   - Processor performance statistics
   - Queue backpressure monitoring

5. **nifi-multi-environment.ndjson** - Multi-Environment Overview Dashboard
   - Cross-site comparative monitoring
   - Environment health cards
   - Resource utilization comparison

6. **nifi-historical-trends.ndjson** - Historical Trends & Capacity Planning Dashboard
   - Long-term analysis with ML forecasts
   - Storage growth projections
   - SLA compliance tracking

7. **nifi-error-analysis.ndjson** - Specific Error Analysis Dashboard
   - Critical error pattern focus
   - Port binding issue analysis
   - Cascading failure detection

## Import Instructions

### Automated Import

Use the setup script:
```bash
./scripts/setup-kibana.sh
```

### Manual Import

1. Navigate to Kibana → Stack Management → Saved Objects
2. Click "Import"
3. Select a dashboard file (.ndjson)
4. Choose import options:
   - ✅ Automatically overwrite conflicts
   - ✅ Create new objects with random IDs
5. Click "Import"

## Customization

### Edit a Dashboard

1. Open the dashboard in Kibana
2. Click "Edit" button
3. Modify visualizations, filters, or layout
4. Click "Save"

### Export Modified Dashboard

1. Navigate to Stack Management → Saved Objects
2. Select the dashboard
3. Click "Export"
4. Save to this directory

## Dashboard Requirements

### Data Views Required

The following data views must exist:
- `nifi-bulletins-*`
- `nifi-system-diagnostics-*`
- `nifi-flow-performance-*`
- `nifi-ml-features-hourly`
- `nifi-ml-error-patterns`

These are created automatically by `./scripts/setup-kibana.sh`

### Time Field

All dashboards use `@timestamp` as the time field.

## Best Practices

### Refresh Intervals

- Executive Overview: 30 seconds
- Operational Dashboards: 1 minute
- Historical Analysis: 1 hour

### Time Ranges

- Real-time monitoring: Last 24 hours
- Troubleshooting: Last 7 days
- Capacity planning: Last 90 days

### Performance Optimization

- Limit panels to 10-15 per dashboard
- Use appropriate aggregation intervals
- Apply filters to reduce data scanned
- Consider data sampling for large time ranges

## Troubleshooting

### Dashboard shows "No results found"

1. Check time range (adjust to last 7 days)
2. Verify data is being ingested
3. Remove all filters
4. Refresh data view field list

### Dashboard not loading

1. Check Elasticsearch connection
2. Verify index patterns exist
3. Clear browser cache
4. Recreate data views

### Visualization errors

1. Check field mappings in index
2. Verify aggregation types
3. Review query syntax
4. Check for missing fields

## Support

For issues with dashboards:
- See [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
- Check [USER-GUIDE.md](../docs/USER-GUIDE.md)
- Open an issue: https://github.com/talentGitHub/ApacheNiFi/issues
