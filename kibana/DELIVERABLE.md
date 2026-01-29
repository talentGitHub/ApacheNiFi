# System Health Dashboard - Deliverable Summary

## Overview

This deliverable provides a complete Kibana dashboard solution for monitoring Apache NiFi's JVM and OS-level health metrics, based on the working dashboard configuration provided from your Elasticsearch Cloud deployment.

## What's Included

### 1. Dashboard Configuration
- **File**: `kibana/dashboards/system-health-dashboard.ndjson`
- **Format**: NDJSON (Kibana import format)
- **Size**: 15.6 KB
- **Kibana Version**: 8.x compatible
- **Status**: ✅ Validated and ready for import

### 2. Documentation
- **README.md**: Quick start guide and import instructions
- **USAGE-GUIDE.md**: Comprehensive guide covering:
  - Dashboard component descriptions
  - Interpretation of each visualization
  - Common use cases and scenarios
  - Troubleshooting tips
  - Best practices

### 3. Automation Scripts
- **import-dashboard.sh**: Automated import via Kibana API
  - Interactive credential prompt
  - Error handling and validation
  - Success confirmation
  
- **validate-setup.sh**: Pre-import validation script
  - Checks Elasticsearch connectivity
  - Verifies index existence
  - Validates required fields
  - Confirms Kibana access

### 4. Configuration Templates
- **kibana.env.example**: Environment configuration template
- **.gitignore**: Protects sensitive credential files

## Dashboard Features

### Visualizations Included

1. **Heap Memory Usage (%) Gauge**
   - Real-time heap utilization
   - Color-coded thresholds (Green: 0-50%, Yellow: 51-80%, Red: 81-100%)
   - Calculated from used/max heap ratio

2. **Heap Usage Trend Chart**
   - Time-series visualization
   - 85% threshold reference line
   - Helps identify memory growth patterns

3. **GC Pause Time Chart**
   - Garbage collection performance by site
   - Average pause time tracking
   - Top 3 sites displayed

4. **Processor Load Average Chart**
   - CPU load monitoring
   - Per-site breakdown
   - 1-minute interval updates

### Data Requirements

**Index Pattern**: `nifi-diag*`

**Required Fields**:
- `@timestamp` (date)
- `site` (string)
- `systemDiagnostics.aggregateSnapshot.usedHeapBytes` (long)
- `systemDiagnostics.aggregateSnapshot.maxHeapBytes` (long)
- `systemDiagnostics.aggregateSnapshot.processorLoadAverage` (double)
- `systemDiagnostics.aggregateSnapshot.garbageCollection.collectionMillis` (long)

## Quick Start

### Option 1: Automated Import (Recommended)

```bash
# Navigate to repository
cd /path/to/ApacheNiFi

# Validate setup (optional but recommended)
./kibana/validate-setup.sh https://your-kibana.kb.cloud https://your-es.cloud

# Import dashboard
./kibana/import-dashboard.sh https://your-kibana.kb.cloud
# Enter credentials when prompted
```

### Option 2: Manual Import via Kibana UI

1. Log in to Kibana
2. Navigate to **Stack Management** → **Saved Objects**
3. Click **Import**
4. Upload `kibana/dashboards/system-health-dashboard.ndjson`
5. Resolve any conflicts (recommend "Automatically overwrite")
6. Access via **Dashboard** → Search "System Health Dashboard"

### Option 3: API Import with cURL

```bash
# Set variables
export KIBANA_URL="https://your-kibana.kb.cloud"
export KIBANA_USER="your-username"
export KIBANA_PASSWORD="your-password"

# Import
curl -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: multipart/form-data" \
  -u "${KIBANA_USER}:${KIBANA_PASSWORD}" \
  -F "file=@kibana/dashboards/system-health-dashboard.ndjson"
```

## Prerequisites

Before importing, ensure:

1. ✅ **Elasticsearch 8.x** deployment with `nifi-diag*` indices
2. ✅ **Kibana 8.x** access with appropriate permissions
3. ✅ **Index Pattern** for `nifi-diag*` exists (or will be created)
4. ✅ **NiFi Data** flowing to Elasticsearch with required fields
5. ✅ **User Permissions**: `kibana_admin` or saved object management rights

## File Structure

```
kibana/
├── .gitignore                          # Protects credential files
├── README.md                           # Quick start guide
├── USAGE-GUIDE.md                      # Comprehensive usage documentation
├── dashboards/
│   └── system-health-dashboard.ndjson # Dashboard configuration
├── import-dashboard.sh                 # Automated import script
├── validate-setup.sh                   # Pre-import validation
└── kibana.env.example                  # Configuration template
```

## Customization Options

### Change Index Pattern

If your index pattern ID differs:

```bash
# Get your index pattern ID from Kibana
# Stack Management → Index Patterns → Copy ID from URL

# Update the dashboard file
sed -i 's/0d3c68e1-a71e-493f-8503-c8700108ed4d/YOUR-INDEX-PATTERN-ID/g' \
  kibana/dashboards/system-health-dashboard.ndjson
```

### Adjust Thresholds

Edit the `gauge_color_rules` section in the dashboard JSON to modify warning/critical levels:

```json
{
  "value": 0,    // Start of range
  "gauge": "rgba(0,191,179,1)",  // Green
  "operator": "gte"
}
```

### Add More Visualizations

1. Import the dashboard
2. Open in Kibana
3. Edit dashboard
4. Add/clone panels as needed
5. Export and replace the `.ndjson` file

## Verification

Run the validation report to confirm everything is ready:

```bash
cd /path/to/ApacheNiFi
python3 << 'EOF'
import json
with open('kibana/dashboards/system-health-dashboard.ndjson', 'r') as f:
    dashboard = json.load(f)
    print(f"✅ Dashboard: {dashboard['attributes']['title']}")
    print(f"✅ Type: {dashboard['type']}")
    print(f"✅ Panels: {len(json.loads(dashboard['attributes']['panelsJSON']))}")
    print(f"✅ Status: Ready for import")
EOF
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Index pattern not found" | Create `nifi-diag*` pattern in Kibana |
| "No results found" | Verify data exists, adjust time range |
| Import fails with 403 | Check user has `kibana_admin` role |
| Fields not found | Verify NiFi is sending correct field structure |
| Connection timeout | Check firewall, VPN, or network settings |

See `kibana/USAGE-GUIDE.md` for detailed troubleshooting.

## Support & Resources

- **Documentation**: See `kibana/README.md` and `kibana/USAGE-GUIDE.md`
- **Issues**: [GitHub Issues](https://github.com/talentGitHub/ApacheNiFi/issues)
- **Validation**: Run `./kibana/validate-setup.sh` before import
- **NiFi Docs**: [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
- **Elastic Docs**: [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)

## Next Steps After Import

1. ✅ Verify dashboard appears in Kibana
2. ✅ Set appropriate time range (e.g., Last 24 hours)
3. ✅ Enable auto-refresh (e.g., every 30 seconds)
4. ✅ Bookmark dashboard for quick access
5. ✅ Configure alerts based on dashboard metrics
6. ✅ Share dashboard with your team
7. ✅ Review `USAGE-GUIDE.md` for interpretation tips

## Maintenance

### Regular Tasks

- **Daily**: Quick health check during business hours
- **Weekly**: Review trends and verify data quality
- **Monthly**: Capacity planning and threshold review
- **Quarterly**: Dashboard optimization and cleanup

### Updates

To update the dashboard:

1. Make changes in Kibana UI
2. Export updated dashboard
3. Replace `system-health-dashboard.ndjson`
4. Commit changes to repository
5. Document changes in commit message

## Technical Specifications

- **Dashboard ID**: `934bd655-36c0-4153-a3ac-f8b53bb29564`
- **Kibana Version**: 8.x (compatible with 8.0+)
- **Core Migration Version**: 8.8.0
- **Type Migration Version**: 10.3.0
- **Index Pattern**: `nifi-diag*` (ID: `0d3c68e1-a71e-493f-8503-c8700108ed4d`)
- **Time Field**: `@timestamp`

## License

This dashboard configuration is part of the Apache NiFi Observability Platform project.
See the main repository LICENSE file for details.

---

**Created**: 2026-01-29  
**Version**: 1.0.0  
**Maintained By**: Platform Engineering Team  
**Repository**: https://github.com/talentGitHub/ApacheNiFi
