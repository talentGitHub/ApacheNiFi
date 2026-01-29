# Alternatives to Kibana for Apache NiFi Observability

## Overview

While this platform's default configuration uses Kibana for visualization and dashboarding, there are several robust alternatives for monitoring Apache NiFi deployments. This document outlines the most viable alternatives, their advantages, trade-offs, and implementation guidance.

## 🎯 Quick Comparison

| Solution | Cost | Ease of Setup | Features | Best For |
|----------|------|---------------|----------|----------|
| **Grafana** | Free/Paid | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Real-time monitoring, multi-source |
| **Apache Superset** | Free | ⭐⭐⭐ | ⭐⭐⭐⭐ | BI analytics, SQL-based exploration |
| **Prometheus + Grafana** | Free | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Metrics-focused monitoring |
| **Metabase** | Free/Paid | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Business users, simple dashboards |
| **Redash** | Free/Paid | ⭐⭐⭐⭐ | ⭐⭐⭐ | SQL analysts, scheduled reports |
| **Custom Web App** | Free | ⭐⭐ | ⭐⭐⭐⭐⭐ | Full customization |
| **Elasticsearch API + Notebooks** | Free | ⭐⭐⭐ | ⭐⭐⭐⭐ | Data scientists, ad-hoc analysis |

---

## 1. 🚀 Grafana (Recommended Alternative)

**Best for**: Organizations already using Grafana, multi-source monitoring, alerting

### Why Grafana?

- **Native Elasticsearch Support**: Direct integration without intermediary tools
- **Flexible Alerting**: More customizable alert rules than Kibana
- **Multi-Source Dashboards**: Combine NiFi metrics with other systems (Prometheus, InfluxDB, MySQL)
- **Community**: Large ecosystem with pre-built dashboards
- **Cost**: Free (OSS) or Grafana Cloud with generous free tier

### Setup Instructions

#### Prerequisites
```bash
# Install Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

#### Configure Elasticsearch Data Source

1. **Access Grafana**: Navigate to `http://localhost:3000` (default credentials: admin/admin)

2. **Add Elasticsearch Data Source**:
   ```json
   {
     "name": "NiFi Elasticsearch",
     "type": "elasticsearch",
     "url": "https://your-cluster.es.cloud.io:9243",
     "access": "proxy",
     "database": "nifi-bulletins-*,nifi-system-diagnostics-*,nifi-flow-performance-*",
     "basicAuth": true,
     "basicAuthUser": "your-username",
     "secureJsonData": {
       "basicAuthPassword": "your-password"
     },
     "jsonData": {
       "esVersion": "8.0.0",
       "timeField": "@timestamp",
       "interval": "Daily",
       "logMessageField": "message",
       "logLevelField": "bulletinLevel"
     }
   }
   ```

3. **Import Dashboard Templates**: Use the provided Grafana dashboard JSON files (see below)

#### Dashboard Migration Guide

**Convert Kibana Visualizations to Grafana Panels**:

| Kibana Viz Type | Grafana Panel Type | Notes |
|-----------------|-------------------|-------|
| Line Chart | Time series | Direct mapping |
| Data Table | Table | Use transformations for aggregations |
| Metric | Stat | Set thresholds for color coding |
| Gauge | Gauge | Map field values to 0-100% |
| Heat Map | Heatmap | Use bucket aggregations |
| TSVB | Time series | Multiple queries for overlays |
| Markdown | Text | HTML/Markdown support |

**Example Dashboard JSON for Executive Overview**:

```json
{
  "dashboard": {
    "title": "NiFi Executive Overview",
    "tags": ["nifi", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "System Status",
        "type": "stat",
        "targets": [
          {
            "query": "runStatus:Running",
            "metrics": [{"type": "count"}],
            "bucketAggs": []
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 1, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Active Errors (Last 5 min)",
        "type": "timeseries",
        "targets": [
          {
            "query": "bulletinLevel:ERROR",
            "timeField": "@timestamp",
            "metrics": [{"type": "count"}],
            "bucketAggs": [
              {"type": "date_histogram", "field": "@timestamp", "interval": "30s"}
            ]
          }
        ]
      },
      {
        "id": 3,
        "title": "JVM Heap Utilization",
        "type": "gauge",
        "targets": [
          {
            "query": "*",
            "metrics": [{"type": "avg", "field": "heapUtilization"}]
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "max": 100,
            "thresholds": {
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 70, "color": "yellow"},
                {"value": 85, "color": "red"}
              ]
            }
          }
        }
      }
    ],
    "refresh": "30s",
    "time": {"from": "now-1h", "to": "now"}
  }
}
```

#### Alerting Configuration

Grafana alerting is more flexible than Kibana's alerting rules:

```yaml
# Example alert rule for JVM memory
- alert: NiFiHighMemoryUsage
  expr: avg(heapUtilization) > 85
  for: 5m
  labels:
    severity: critical
    component: jvm
  annotations:
    summary: "NiFi JVM heap utilization critical"
    description: "Heap utilization is {{ $value }}% for 5 minutes"
```

**Configure Notification Channels**:
- Slack: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
- Email: SMTP settings in `grafana.ini`
- PagerDuty: Integration key in notification channel
- Webhook: POST to auto-remediation endpoint

### Advantages
✅ More flexible query builder  
✅ Better alerting and notification management  
✅ Can combine NiFi metrics with other data sources  
✅ Templating and variables for dynamic dashboards  
✅ Active development and large community  

### Trade-offs
⚠️ Learning curve for teams already familiar with Kibana  
⚠️ Elasticsearch plugin less mature than native Kibana integration  
⚠️ Some advanced Kibana features (Canvas, Lens) not available  

---

## 2. 📊 Apache Superset

**Best for**: BI analytics, SQL power users, cross-database exploration

### Why Superset?

- **SQL-First Approach**: Native SQL editor with syntax highlighting
- **Semantic Layer**: Define metrics once, reuse across dashboards
- **Advanced Analytics**: Statistical functions, forecasting, cohort analysis
- **Role-Based Access**: Fine-grained permissions on datasets and dashboards
- **Free & Open Source**: Apache 2.0 license, no vendor lock-in

### Setup Instructions

```bash
# Install via Docker
docker run -d -p 8088:8088 \
  --name superset \
  -e "SUPERSET_SECRET_KEY=$(openssl rand -base64 42)" \
  apache/superset

# Initialize database
docker exec -it superset superset db upgrade
docker exec -it superset superset fab create-admin \
  --username admin --firstname Admin --lastname User \
  --email admin@example.com --password admin
docker exec -it superset superset init
```

#### Configure Elasticsearch Connection

Superset uses SQLAlchemy, which requires an Elasticsearch dialect:

```bash
# Install Elasticsearch connector
pip install elasticsearch-dbapi

# Connection string format
elasticsearch+http://username:password@your-cluster.es.cloud.io:9243
```

**Add Database**:
1. Navigate to Data > Databases > + Database
2. Select "Elasticsearch" from supported databases
3. Enter connection string and test connection

#### Create Datasets

Define virtual datasets from Elasticsearch indices:

```sql
-- Bulletins dataset
SELECT
  "@timestamp" as timestamp,
  bulletinLevel as level,
  bulletinMessage as message,
  bulletinSourceName as source,
  bulletinCategory as category
FROM "nifi-bulletins-*"
WHERE "@timestamp" >= NOW() - 7 * 24 * 60 * 60 * 1000  -- 7 days in milliseconds
```

#### Build Dashboards

1. **Create Charts**: Use the no-code chart builder or SQL Lab
2. **Design Dashboard**: Drag-and-drop layout with filters
3. **Set Refresh**: Auto-refresh every 30 seconds to 1 hour

### Sample Dashboard Structure

```
┌─────────────────────────────────────────────────────┐
│  NiFi Executive Dashboard                           │
├───────────┬─────────────────────┬───────────────────┤
│  KPI Card │  KPI Card          │  KPI Card         │
│  Status   │  Error Count       │  Throughput       │
├───────────┴─────────────────────┴───────────────────┤
│  Error Trend (Last 24h)                             │
│  [Line Chart]                                       │
├─────────────────────────────────────────────────────┤
│  Top Error Messages            │  Error Heatmap    │
│  [Table]                       │  [Heatmap]        │
└─────────────────────────────────────────────────────┘
```

### Advantages
✅ Excellent for BI and analytical queries  
✅ Scheduled reports and email delivery  
✅ Row-level security for multi-tenant deployments  
✅ Rich semantic layer for business metrics  

### Trade-offs
⚠️ Less suitable for real-time operational monitoring  
⚠️ Elasticsearch support less mature than relational databases  
⚠️ Higher resource consumption than Grafana  

---

## 3. 📈 Prometheus + Grafana Stack

**Best for**: Metrics-focused monitoring, Kubernetes deployments, alerting-first approach

### Architecture

```
┌──────────────┐     ┌────────────────┐     ┌──────────┐
│  NiFi        │────▶│  NiFi Exporter │────▶│ Prometheus│
│  Reporting   │     │  (Custom)      │     │           │
│  Tasks       │     └────────────────┘     └─────┬─────┘
└──────────────┘                                   │
                                                   │
                                            ┌──────▼──────┐
                                            │   Grafana   │
                                            └─────────────┘
```

### Implementation

#### Step 1: Create NiFi Prometheus Exporter

NiFi doesn't have native Prometheus metrics, so we need to export from Elasticsearch:

```python
# nifi_exporter.py
from prometheus_client import start_http_server, Gauge
from elasticsearch import Elasticsearch
import time

# Initialize metrics
heap_utilization = Gauge('nifi_heap_utilization', 'JVM Heap Utilization')
error_count = Gauge('nifi_error_count_5m', 'Errors in last 5 minutes')
queue_count = Gauge('nifi_queue_count', 'Total queued flowfiles')

# Connect to Elasticsearch
es = Elasticsearch(['https://your-cluster.es.cloud.io:9243'],
                   basic_auth=('username', 'password'))

def collect_metrics():
    # Heap utilization
    result = es.search(
        index='nifi-system-diagnostics-*',
        query={'match_all': {}},
        size=1,
        sort=[{'@timestamp': 'desc'}]
    )
    if result['hits']['hits']:
        heap_utilization.set(result['hits']['hits'][0]['_source']['heapUtilization'])
    
    # Error count (last 5 min)
    result = es.count(
        index='nifi-bulletins-*',
        query={
            'bool': {
                'must': [
                    {'term': {'bulletinLevel': 'ERROR'}},
                    {'range': {'@timestamp': {'gte': 'now-5m'}}}
                ]
            }
        }
    )
    error_count.set(result['count'])

if __name__ == '__main__':
    start_http_server(9091)  # Use 9091 to avoid conflict with Prometheus on 9090
    while True:
        collect_metrics()
        time.sleep(15)  # Scrape every 15 seconds
```

#### Step 2: Configure Prometheus

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'nifi'
    static_configs:
      - targets: ['localhost:9091']  # NiFi exporter port
        labels:
          environment: 'production'
```

#### Step 3: Grafana Dashboards

Use Prometheus as data source in Grafana and leverage PromQL:

```promql
# CPU usage trend
rate(nifi_processor_processing_nanos[5m])

# Error rate
increase(nifi_error_count_5m[1h])

# Predict queue growth (using Prometheus ML)
predict_linear(nifi_queue_count[1h], 3600)
```

### Advantages
✅ Industry-standard metrics format  
✅ Efficient time-series storage  
✅ Powerful PromQL query language  
✅ Native Kubernetes integration  
✅ Excellent alerting with AlertManager  

### Trade-offs
⚠️ Requires custom exporter for NiFi  
⚠️ Less suitable for log analysis (use Loki alongside)  
⚠️ Additional infrastructure to maintain  

---

## 4. 🔍 Metabase

**Best for**: Business users, non-technical stakeholders, simple dashboards

### Why Metabase?

- **No SQL Required**: Visual query builder for business users
- **Easy Setup**: 5-minute installation with Docker
- **Beautiful UI**: Modern, intuitive interface
- **Embedded Analytics**: Share dashboards publicly or embed in apps

### Quick Start

```bash
# Run Metabase
docker run -d -p 3000:3000 \
  --name metabase \
  metabase/metabase
```

**Configure Elasticsearch**:
- Add Database > Elasticsearch
- Use JDBC driver: `elasticsearch-sql-jdbc-8.x.jar`
- Connection string: `jdbc:elasticsearch://https://your-cluster.es.cloud.io:9243`

### Sample Use Cases

1. **Executive Dashboard**: High-level KPIs without technical details
2. **Weekly Reports**: Automated email with key metrics
3. **Public Status Page**: Embed uptime and performance metrics
4. **Self-Service**: Business users explore data without SQL

### Advantages
✅ Extremely user-friendly  
✅ Fast setup and onboarding  
✅ Great for non-technical users  
✅ Free and open source  

### Trade-offs
⚠️ Limited advanced analytics  
⚠️ Elasticsearch support via SQL only  
⚠️ Less suitable for real-time operational monitoring  

---

## 5. 🎨 Redash

**Best for**: SQL analysts, scheduled reports, query sharing

### Why Redash?

- **SQL-Centric**: Native SQL editor with auto-complete
- **Query Sharing**: Parameterized queries as building blocks
- **API Integration**: Programmatic access to query results
- **Alerts**: Query-based alerting with thresholds

### Setup

```bash
# Clone Redash setup
git clone https://github.com/getredash/setup.git
cd setup
./setup.sh
```

**Add Elasticsearch Data Source**:
- Type: Elasticsearch
- URL: `https://your-cluster.es.cloud.io:9243`
- Index: `nifi-*`

### Example Queries

```sql
-- Top 10 error messages today
SELECT bulletinMessage, COUNT(*) as count
FROM "nifi-bulletins-*"
WHERE bulletinLevel = 'ERROR'
  AND "@timestamp" >= NOW() - 24 * 60 * 60 * 1000  -- Today (24 hours ago)
GROUP BY bulletinMessage
ORDER BY count DESC
LIMIT 10
```

### Advantages
✅ Powerful SQL editor  
✅ Query scheduling and caching  
✅ API for programmatic access  
✅ Parameterized dashboards  

### Trade-offs
⚠️ Requires SQL knowledge  
⚠️ Less visual customization than Grafana  
⚠️ Elasticsearch support via SQL only  

---

## 6. 🛠️ Custom Web Application

**Best for**: Unique requirements, full control, integration with existing systems

### Technology Stack Options

#### Option A: React + Elasticsearch.js

```javascript
// components/NiFiDashboard.jsx
import { Client } from '@elastic/elasticsearch';
import React, { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip } from 'recharts';

const client = new Client({
  node: 'https://your-cluster.es.cloud.io:9243',
  auth: { username: 'user', password: 'pass' }
});

function HeapUtilizationChart() {
  const [data, setData] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      const result = await client.search({
        index: 'nifi-system-diagnostics-*',
        query: { range: { '@timestamp': { gte: 'now-1h' }}},
        sort: [{ '@timestamp': 'asc' }],
        size: 100
      });
      
      const chartData = result.hits.hits.map(hit => ({
        timestamp: hit._source['@timestamp'],
        heap: hit._source.heapUtilization
      }));
      
      setData(chartData);
    };
    
    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30s
    
    return () => clearInterval(interval);
  }, []);

  return (
    <LineChart width={600} height={300} data={data}>
      <XAxis dataKey="timestamp" />
      <YAxis domain={[0, 100]} />
      <Tooltip />
      <Line type="monotone" dataKey="heap" stroke="#8884d8" />
    </LineChart>
  );
}

export default HeapUtilizationChart;
```

#### Option B: Python Flask + Plotly Dash

```python
# app.py
import dash
from dash import dcc, html
from dash.dependencies import Input, Output
import plotly.graph_objs as go
from elasticsearch import Elasticsearch

app = dash.Dash(__name__)
es = Elasticsearch(['https://your-cluster.es.cloud.io:9243'],
                   basic_auth=('user', 'pass'))

app.layout = html.Div([
    html.H1('NiFi Real-Time Monitor'),
    dcc.Graph(id='heap-gauge'),
    dcc.Interval(id='interval', interval=30*1000)  # Update every 30s
])

@app.callback(
    Output('heap-gauge', 'figure'),
    Input('interval', 'n_intervals')
)
def update_heap_gauge(n):
    result = es.search(
        index='nifi-system-diagnostics-*',
        query={'match_all': {}},
        size=1,
        sort=[{'@timestamp': 'desc'}]
    )
    
    # Handle case when no results are returned
    if not result['hits']['hits']:
        heap = 0
    else:
        heap = result['hits']['hits'][0]['_source']['heapUtilization']
    
    fig = go.Figure(go.Indicator(
        mode='gauge+number',
        value=heap,
        title={'text': 'JVM Heap Utilization'},
        gauge={'axis': {'range': [None, 100]},
               'threshold': {'line': {'color': 'red', 'width': 4}, 'value': 85}}
    ))
    
    return fig

if __name__ == '__main__':
    app.run_server(debug=True)
```

### Advantages
✅ Complete customization  
✅ Integrate with existing authentication systems  
✅ Add custom business logic  
✅ Optimized for specific use cases  

### Trade-offs
⚠️ Requires development effort  
⚠️ Ongoing maintenance burden  
⚠️ Need to build features from scratch  

---

## 7. 📓 Elasticsearch API + Jupyter Notebooks

**Best for**: Data scientists, ad-hoc analysis, exploratory data analysis

### Setup

```bash
# Install Jupyter and Elasticsearch libraries
pip install jupyter elasticsearch pandas matplotlib seaborn
jupyter notebook
```

### Example Notebook

```python
# Cell 1: Connect to Elasticsearch
from elasticsearch import Elasticsearch
import pandas as pd
import matplotlib.pyplot as plt

es = Elasticsearch(['https://your-cluster.es.cloud.io:9243'],
                   basic_auth=('user', 'pass'))

# Cell 2: Fetch and analyze bulletins
result = es.search(
    index='nifi-bulletins-*',
    query={'range': {'@timestamp': {'gte': 'now-7d'}}},
    size=10000
)

df = pd.DataFrame([hit['_source'] for hit in result['hits']['hits']])

# Cell 3: Error analysis
error_counts = df[df['bulletinLevel'] == 'ERROR'].groupby('bulletinCategory').size()
error_counts.plot(kind='bar', title='Errors by Category (Last 7 Days)')
plt.show()

# Cell 4: Time series analysis
df['@timestamp'] = pd.to_datetime(df['@timestamp'])
df.set_index('@timestamp', inplace=True)
hourly_errors = df[df['bulletinLevel'] == 'ERROR'].resample('1H').size()
hourly_errors.plot(title='Hourly Error Rate')
plt.show()
```

### Advantages
✅ Flexible ad-hoc analysis  
✅ Combine with other data sources (CSV, databases)  
✅ Advanced statistical analysis  
✅ Export to reports or dashboards  

### Trade-offs
⚠️ Not suitable for operational monitoring  
⚠️ Requires Python knowledge  
⚠️ No alerting capabilities  

---

## 🔄 Migration Strategy

### Phase 1: Parallel Running (2 weeks)
- Deploy alternative visualization tool alongside Kibana
- Replicate 1-2 critical dashboards
- Gather user feedback

### Phase 2: Full Migration (2 weeks)
- Migrate all dashboards to new platform
- Train users on new interface
- Update alerting rules

### Phase 3: Kibana Deprecation (1 week)
- Decommission Kibana
- Archive Kibana dashboards as JSON backups
- Update documentation

### Rollback Plan
- Keep Kibana running but read-only for 30 days
- Export all Kibana dashboards as `.ndjson` before removal
- Document any gaps in functionality

---

## 🎯 Decision Matrix

### Choose Grafana if:
- You need multi-source dashboards (NiFi + other systems)
- Alerting is critical
- Your team already uses Grafana for other services
- You want an active community and plugin ecosystem

### Choose Apache Superset if:
- You need BI-style analytics and SQL exploration
- Role-based access control is important
- You want a semantic layer for business metrics
- Your users are comfortable with SQL

### Choose Prometheus + Grafana if:
- You're running on Kubernetes
- You want industry-standard metrics format
- Alerting and incident management are priorities
- You can invest in building custom exporters

### Choose Metabase if:
- Your users are non-technical business stakeholders
- You need simple, beautiful dashboards quickly
- SQL knowledge is limited
- You want embedded analytics

### Choose Custom Solution if:
- You have unique requirements not met by existing tools
- You need deep integration with internal systems
- You have development resources available
- Full control and customization are priorities

---

## 📚 Additional Resources

### Grafana
- Official Documentation: https://grafana.com/docs/
- Elasticsearch Data Source: https://grafana.com/docs/grafana/latest/datasources/elasticsearch/
- Dashboard Examples: https://grafana.com/grafana/dashboards/

### Apache Superset
- Official Documentation: https://superset.apache.org/docs/intro
- Elasticsearch Support: https://superset.apache.org/docs/databases/elasticsearch

### Prometheus
- Official Documentation: https://prometheus.io/docs/
- Best Practices: https://prometheus.io/docs/practices/naming/

### Metabase
- Official Documentation: https://www.metabase.com/docs/latest/
- Elasticsearch Guide: https://www.metabase.com/docs/latest/databases/elasticsearch

### Redash
- Official Documentation: https://redash.io/help/
- Data Sources: https://redash.io/help/data-sources/querying/

---

## 🤝 Need Help?

If you need assistance choosing or implementing an alternative:

1. **Open a Discussion**: https://github.com/talentGitHub/ApacheNiFi/discussions
2. **File an Issue**: https://github.com/talentGitHub/ApacheNiFi/issues
3. **Community Support**: Join our Slack channel

We're here to help you build the best observability solution for your NiFi deployment!

---

**Last Updated**: 2026-01-29  
**Maintained by**: Platform Engineering Team
