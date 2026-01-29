# Kibana Dashboard Quick Start Guide

This quick start guide will help you get your Kibana dashboards up and running in 15 minutes.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Kibana 8.x** instance running and accessible
- [ ] **Admin credentials** or API key for Kibana
- [ ] **NiFi data** flowing into Elasticsearch (indices: `nifi-bulletins-*`, `nifi-system-diagnostics-*`, `nifi-flow-performance-*`)
- [ ] **curl** installed on your machine
- [ ] This repository cloned locally

## 5-Minute Setup (Automated)

### Step 1: Navigate to Repository

```bash
cd /path/to/ApacheNiFi
```

### Step 2: Run Setup Script

```bash
./scripts/setup-kibana.sh
```

### Step 3: Follow Prompts

The script will ask for:
1. **Kibana URL**: e.g., `https://your-deployment.kb.cloud.elastic.io`
2. **Authentication**: Choose API Key (recommended) or Username/Password
3. **Credentials**: Enter your API key or password

### Step 4: Verify Setup

The script will automatically:
- ✅ Verify Kibana connectivity
- ✅ Create 5 index patterns (data views)
- ✅ Import all 7 dashboards
- ✅ Confirm successful import

### Step 5: Access Dashboards

1. Open your Kibana instance in a browser
2. Navigate to **Analytics** → **Dashboard**
3. Look for dashboards starting with "NiFi"
4. Open **NiFi Executive Overview** to start

## 10-Minute Setup (Manual)

If the script doesn't work or you prefer manual control:

### Step 1: Create Index Patterns

1. Open Kibana → **Stack Management** → **Data Views**
2. Create these data views:

   | Name | Index Pattern | Time Field |
   |------|---------------|------------|
   | NiFi Bulletins | `nifi-bulletins-*` | `@timestamp` |
   | NiFi System Diagnostics | `nifi-system-diagnostics-*` | `@timestamp` |
   | NiFi Flow Performance | `nifi-flow-performance-*` | `@timestamp` |
   | NiFi ML Features Hourly | `nifi-ml-features-hourly` | `@timestamp` |
   | NiFi ML Error Patterns | `nifi-ml-error-patterns` | `@timestamp` |

### Step 2: Import Dashboards

1. Go to **Stack Management** → **Saved Objects**
2. Click **Import**
3. Select all `.ndjson` files from `kibana/dashboards/` directory
4. Enable "Automatically overwrite conflicts"
5. Click **Import**

### Step 3: Configure Time Ranges

For each dashboard, set recommended time ranges:

- **Executive Overview**: Last 15 minutes, auto-refresh 30s
- **Bulletin Deep Dive**: Last 1 hour
- **System Diagnostics**: Last 4 hours, auto-refresh 1m
- **Flow Performance**: Last 24 hours
- **Multi-Environment**: Last 1 hour, auto-refresh 1m
- **Historical Trends**: Last 90 days
- **Specific Error Analysis**: Last 7 days

## Troubleshooting Quick Fixes

### "No Data" in Dashboards

**Quick Fix**:
1. Expand time range to **Last 30 days**
2. Go to **Discover** → select index pattern → verify data exists
3. Check NiFi is sending data to Elasticsearch

### "Index Pattern Not Found"

**Quick Fix**:
1. Create index patterns first (Step 1 in manual setup)
2. Re-import dashboards

### Dashboards Load Slowly

**Quick Fix**:
1. Reduce time range to last 24 hours
2. Disable auto-refresh temporarily
3. Check Elasticsearch cluster health

## Next Steps

After setup:

1. **Customize Dashboards**: Edit panels to match your specific needs
2. **Set Up Alerts**: Create alert rules from dashboard panels
3. **Configure Access**: Set up role-based access control
4. **Schedule Reports**: Set up PDF/CSV report generation

## Getting Help

- **Detailed Guide**: See [KIBANA-SETUP-GUIDE.md](KIBANA-SETUP-GUIDE.md) for comprehensive instructions
- **GitHub Issues**: Report problems at https://github.com/talentGitHub/ApacheNiFi/issues
- **Community**: Ask questions via GitHub Discussions
- **Troubleshooting**: See "Troubleshooting" section in the detailed guide

## Dashboard Overview

### 1. Executive Overview
Single-pane-of-glass for stakeholders. Shows system status, active errors, JVM health, and processor status.

**Best for**: NOC monitoring, quick health checks, executive reporting

### 2. Bulletin Deep Dive
Comprehensive error analysis. Shows error timeline, top errors, error distribution, and live bulletin stream.

**Best for**: Troubleshooting, root cause analysis, trend analysis

### 3. System Diagnostics Health
JVM and system monitoring. Shows heap/non-heap memory, GC performance, storage, CPU, and threads.

**Best for**: Performance tuning, capacity planning, memory leak detection

### 4. Flow Performance Analytics
Processor and connection performance. Shows throughput, processing times, queue backpressure, and connection details.

**Best for**: Performance optimization, bottleneck identification, flow tuning

### 5. Multi-Environment Overview
Cross-environment comparison. Shows health across dev/stage/prod with comparative metrics.

**Best for**: Multi-datacenter monitoring, environment comparison

### 6. Historical Trends & Capacity Planning
Long-term analysis with ML forecasting. Shows growth trends, capacity projections, and SLA compliance.

**Best for**: Capacity planning, budget forecasting, SLA reporting

### 7. Specific Error Analysis
Critical error pattern deep dive. Focuses on port binding, cache server, and controller service errors.

**Best for**: Incident investigation, root cause analysis, failure pattern recognition

## Tips for Success

1. **Start with Executive Overview** - Get familiar with the overall system status
2. **Use Time Range Picker** - Adjust to match when your data was collected
3. **Enable Auto-Refresh** - For real-time monitoring (Executive Overview, System Diagnostics)
4. **Create Bookmarks** - Save frequently used time ranges and filters
5. **Share Dashboards** - Use Kibana's sharing features to collaborate with team

---

**Setup Time**: 5-15 minutes  
**Difficulty**: Easy  
**Support**: See [KIBANA-SETUP-GUIDE.md](KIBANA-SETUP-GUIDE.md) for detailed help
