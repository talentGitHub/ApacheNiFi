# Kibana Dashboards

This directory contains Kibana dashboard configurations for monitoring Apache NiFi deployments.

## Available Dashboards

### System Health Dashboard
**File**: `dashboards/system-health-dashboard.ndjson`

Monitors JVM and OS-level health metrics across all NiFi sites.

**Panels**:
1. **Heap Memory usage (%)** - Gauge visualization showing current heap utilization with color-coded thresholds:
   - Green (0-50%): Normal operation
   - Yellow (51-80%): Moderate usage
   - Red (81-100%): Critical - requires attention

2. **Heap Usage Trend** - Time-series chart showing heap memory consumption over time with an 85% threshold reference line

3. **GC Pause Time** - Garbage collection pause times by site, helps identify GC-related performance issues

4. **Processor Load Average** - CPU load average trends across different sites

**Data Source**: `nifi-diag*` index pattern

**Fields Used**:
- `systemDiagnostics.aggregateSnapshot.usedHeapBytes`
- `systemDiagnostics.aggregateSnapshot.maxHeapBytes`
- `systemDiagnostics.aggregateSnapshot.garbageCollection.collectionMillis`
- `systemDiagnostics.aggregateSnapshot.processorLoadAverage`
- `@timestamp`
- `site`

## Importing Dashboards to Kibana

### Method 1: Via Kibana UI

1. **Log in to your Kibana instance**
   - Navigate to your Elasticsearch Cloud deployment
   - Open Kibana

2. **Navigate to Stack Management**
   - Click on the menu icon (☰) in the top-left corner
   - Select **Stack Management** from the menu
   - Click on **Saved Objects** under Kibana section

3. **Import the Dashboard**
   - Click the **Import** button in the top-right corner
   - Click **Import** and select the `.ndjson` file
   - Or drag and drop the `system-health-dashboard.ndjson` file

4. **Handle Conflicts** (if any)
   - If prompted about conflicts, choose:
     - **Automatically overwrite conflicts**: To replace existing dashboards
     - **Request action on each conflict**: To review each conflict individually

5. **Configure Index Pattern**
   - The dashboard expects an index pattern with ID `0d3c68e1-a71e-493f-8503-c8700108ed4d`
   - If your index pattern ID is different, you'll need to:
     - Create or identify your `nifi-diag*` index pattern
     - Update the references during import
     - Or modify the `.ndjson` file to use your index pattern ID

6. **Access the Dashboard**
   - Go to **Dashboard** from the main menu
   - Search for "System Health Dashboard"
   - Click to open and view

### Method 2: Via API

```bash
# Set your Kibana URL and credentials
KIBANA_URL="https://your-kibana-instance.kb.cloud"
KIBANA_USER="your-username"
KIBANA_PASSWORD="your-password"

# Import the dashboard
curl -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: multipart/form-data" \
  -u "${KIBANA_USER}:${KIBANA_PASSWORD}" \
  -F "file=@kibana/dashboards/system-health-dashboard.ndjson"
```

### Method 3: Using Elasticsearch Cloud Console

1. Log in to [Elasticsearch Cloud](https://cloud.elastic.co/)
2. Select your deployment
3. Click on **Kibana** to open it
4. Follow the steps in Method 1 above

## Prerequisites

Before importing the dashboards, ensure:

1. **Index Pattern Exists**: Create an index pattern for `nifi-diag*` if it doesn't exist
   - Go to **Stack Management** → **Index Patterns**
   - Click **Create index pattern**
   - Enter `nifi-diag*` as the pattern
   - Select `@timestamp` as the time field

2. **Data is Available**: Ensure NiFi is sending system diagnostics data to Elasticsearch
   - Check that the `nifi-diag*` indices exist and contain data
   - Verify the required fields are present in your documents

3. **Appropriate Permissions**: Your Kibana user must have:
   - Read access to `nifi-diag*` indices
   - Permission to create/import saved objects

## Customization

### Updating Index Pattern References

If your index pattern ID differs from the default (`0d3c68e1-a71e-493f-8503-c8700108ed4d`):

1. Get your index pattern ID:
   - Go to **Stack Management** → **Index Patterns**
   - Click on your `nifi-diag*` pattern
   - Copy the ID from the URL (e.g., `/app/management/kibana/indexPatterns/patterns/YOUR-ID-HERE`)

2. Update the dashboard file:
   ```bash
   # Replace OLD_ID with the ID from the file and NEW_ID with your actual ID
   sed -i 's/0d3c68e1-a71e-493f-8503-c8700108ed4d/YOUR-NEW-INDEX-PATTERN-ID/g' \
     kibana/dashboards/system-health-dashboard.ndjson
   ```

### Adjusting Thresholds

To modify the heap memory gauge thresholds, edit the `gauge_color_rules` in the dashboard JSON:
- Current thresholds: 0-50% (green), 51-80% (yellow), 81-100% (red)
- Edit the `value` fields to adjust threshold boundaries

### Changing Refresh Intervals

The dashboard uses default Kibana time settings. To set auto-refresh:
1. Open the dashboard in Kibana
2. Click the time picker in the top-right
3. Select **Refresh every** and choose your desired interval (e.g., 30s, 1m, 5m)
4. Click **Save** to persist the setting

## Troubleshooting

### "Index pattern not found" error
- Ensure the `nifi-diag*` index pattern exists in Kibana
- Update the index pattern references if using a different pattern name

### Visualizations show "No results found"
- Verify that data exists in your `nifi-diag*` indices
- Check the time range in the time picker
- Ensure the required fields exist in your data

### Permission errors during import
- Verify you have the `kibana_admin` role or appropriate saved object management permissions
- Contact your Elasticsearch administrator if you need elevated permissions

## Support

For issues or questions:
- Review the main [README](../README.md) for platform documentation
- Check the [troubleshooting guide](../docs/TROUBLESHOOTING.md)
- Open an issue on [GitHub](https://github.com/talentGitHub/ApacheNiFi/issues)
