# Architecture Documentation

Technical architecture and design decisions for the Apache NiFi Observability Platform.

## System Overview

The platform implements a comprehensive observability stack for Apache NiFi with four main layers:

```
┌─────────────────────────────────────────────────────┐
│              Data Collection Layer                  │
│  Apache NiFi → Bulletins, Diagnostics, Flow Data   │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│              Storage & Processing Layer             │
│  Elasticsearch: Indexing, ILM, ML, Transforms      │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│           Visualization & Analysis Layer            │
│  Kibana: Dashboards, Alerts, Canvas Reports        │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│         Intelligence & Automation Layer             │
│  LLM Service: Analysis, Recommendations, Actions    │
└─────────────────────────────────────────────────────┘
```

## Data Streams

### 1. Bulletin Stream

**Collection Frequency**: Every 10 seconds  
**Purpose**: Real-time error tracking and alerting  
**Index Pattern**: `nifi-bulletins-YYYY.MM.DD-000001`

**Schema**:
- `@timestamp`: Event timestamp
- `bulletinId`: Unique identifier
- `bulletinLevel`: ERROR, WARN, INFO
- `bulletinMessage`: Error/warning message
- `bulletinSourceName`: Component name
- `bulletinSourceType`: Component type
- `errorCategory`: Enriched error classification
- `severityScore`: Numeric severity (1-10)
- `extractedPort`: Port number if applicable

**Enrichments** (via ingest pipeline):
- Severity scoring based on level
- Error categorization (PORT_CONFLICT, MEMORY_ERROR, etc.)
- Port number extraction from messages
- Timestamp normalization

### 2. System Diagnostics Stream

**Collection Frequency**: Every 1 minute  
**Purpose**: JVM health, resource monitoring  
**Index Pattern**: `nifi-system-diagnostics-YYYY.MM.DD-000001`

**Schema**:
- `@timestamp`: Measurement timestamp
- `heapUtilization`: Calculated percentage
- `usedHeapBytes`, `maxHeapBytes`: JVM heap metrics
- `processorLoadAverage`: CPU load
- `totalThreads`: Thread count
- `gcStats`: Garbage collection metrics
- `storageUsage`: Array of storage repository metrics

**Enrichments**:
- Heap utilization percentage calculation
- Storage utilization percentages
- GC average duration calculation

### 3. Flow Performance Stream

**Collection Frequency**: Every 1 hour  
**Purpose**: Processor throughput and queue monitoring  
**Index Pattern**: `nifi-flow-performance-YYYY.MM.DD-000001`

**Schema**:
- `@timestamp`: Collection timestamp
- `componentName`, `componentId`: Processor identification
- `processorType`: Processor class
- `bytesTransferred`: Total bytes processed
- `invocations`: Execution count
- `processingMillis`: Total processing time
- `queuedCount`: Queue depth
- `queueUtilization`: Calculated utilization percentage

**Enrichments**:
- Processing time conversion (nanos → millis)
- Average processing time calculation
- Queue utilization percentage
- Processing efficiency metrics

## Index Lifecycle Management

### Bulletins ILM Policy

```
Hot Phase (0 days):
  - Rollover: 50GB or 1 day or 10M docs
  - Priority: 100

Warm Phase (7 days):
  - Forcemerge to 1 segment
  - Shrink to 1 shard
  - Priority: 50

Delete Phase (30 days):
  - Delete index
```

### System Diagnostics & Flow Performance ILM

```
Hot Phase (0 days):
  - Rollover: 30GB or 7 days or 5M docs
  - Priority: 100

Warm Phase (30 days):
  - Forcemerge to 1 segment
  - Shrink to 1 shard
  - Priority: 50

Cold Phase (60 days):
  - Freeze index
  - Priority: 0

Delete Phase (90 days):
  - Delete index
```

## Machine Learning Architecture

### Anomaly Detection Jobs

#### 1. Processing Time Anomaly Detection

**Algorithm**: Time series anomaly detection  
**Bucket Span**: 15 minutes  
**Model Memory**: Default (256MB)

**Detectors**:
- High mean processing time by component
- Mean invocations by component (identifies unusual activity)
- High sum processing nanos by processor type

**Use Case**: Detects performance degradation before it impacts users

#### 2. Queue Growth Forecasting

**Algorithm**: Time series forecasting  
**Bucket Span**: 1 hour  
**Model Memory**: 512MB  
**Forecast Horizon**: 24 hours

**Detectors**:
- Mean queue count by component (for forecasting)
- High mean queue size by component (for anomalies)
- Mean queue utilization by environment

**Use Case**: Predicts when queues will reach backpressure

#### 3. Error Spike Detection

**Algorithm**: Count and rare detection  
**Bucket Span**: 5 minutes  
**Model Memory**: 256MB

**Detectors**:
- High count by error category
- Rare error categories (identifies new error types)
- Count by source name
- High count by source type over environment

**Use Case**: Early warning for cascading failures

### Transform Jobs

#### 1. Hourly Processor Performance

**Type**: Continuous transform  
**Frequency**: 1 hour  
**Destination**: `nifi-ml-features-hourly`

**Aggregations**:
- Average/max processing time
- Total invocations and bytes
- Average queue utilization
- Processing efficiency metrics

**Use Case**: Feature engineering for ML models and historical analysis

#### 2. Error Pattern Analysis

**Type**: Continuous transform  
**Frequency**: 10 minutes  
**Destination**: `nifi-ml-error-patterns`

**Aggregations**:
- Error counts by category, source, level
- Unique source cardinality
- Severity scores
- First/last occurrence timestamps
- Affected process groups

**Use Case**: Pattern recognition for predictive alerting

## LLM Analysis Service

### Architecture

```
┌─────────────────────────────────────────┐
│         Flask Application               │
│  - Health checks                        │
│  - Request routing                      │
│  - Response formatting                  │
└──────────┬──────────────────────────────┘
           │
           ├─────────────────┐
           ↓                 ↓
┌─────────────────┐   ┌─────────────────┐
│  Elasticsearch  │   │   LLM Client    │
│    Client       │   │  (OpenAI/       │
│  - Context      │   │   Anthropic/    │
│    retrieval    │   │   Azure)        │
│  - Result       │   │  - Analysis     │
│    storage      │   │  - Generation   │
└─────────────────┘   └─────────────────┘
```

### Analysis Workflow

1. **Context Gathering**:
   - Retrieve specific bulletin
   - Find related bulletins (same source, last hour)
   - Get recent system diagnostics
   - Get performance metrics for affected component

2. **Prompt Construction**:
   - Bulletin details and error category
   - Related error patterns
   - System health metrics
   - Recent performance data

3. **LLM Analysis**:
   - Submit to configured LLM provider
   - Request structured JSON response
   - Parse and validate output

4. **Result Storage**:
   - Store analysis in `nifi-analysis-results` index
   - Include timestamp and confidence score
   - Return to caller

### Supported LLM Providers

- **OpenAI**: GPT-4, GPT-4-turbo, GPT-3.5-turbo
- **Anthropic**: Claude 3 Opus, Sonnet, Haiku
- **Azure OpenAI**: Any deployed model
- **Custom**: Any OpenAI-compatible API

## Dashboard Architecture

### Executive Overview

**Refresh**: 30 seconds  
**Purpose**: Single-pane-of-glass for stakeholders

**Key Visualizations**:
- Metric: System status (calculated from error rate)
- Metric: Active error count (last 5 minutes)
- Gauge: Queue backpressure (max utilization)
- Line chart: JVM memory timeline
- Area chart: Error rate over time
- Heatmap: Processor health by component

### Bulletin Deep Dive

**Purpose**: Troubleshooting and root cause analysis

**Key Visualizations**:
- Stacked area: Bulletins by level over time
- Data table: Top 10 error messages with counts
- Pie chart: Error distribution by category
- Heatmap: Errors by hour of day and day of week
- Search: Live bulletin stream with filters

### System Diagnostics Health

**Purpose**: Resource monitoring and capacity planning

**Key Visualizations**:
- Gauges: Heap and non-heap utilization
- Line charts: Memory usage over time
- Bar charts: GC performance metrics
- Progress bars: Storage utilization
- Metrics: CPU and thread counts

## Security Architecture

### Authentication & Authorization

**Elasticsearch/Kibana**:
- API key authentication (recommended)
- Username/password authentication (supported)
- Role-based access control (RBAC)
- TLS/SSL encryption

**LLM Service**:
- Internal network only (no external exposure)
- Environment variable configuration
- API key storage in Docker secrets

### Data Privacy

**Bulletin Anonymization**:
- PII detection and removal (optional)
- Sensitive data masking
- Audit logging of all analyses

**Access Logs**:
- All analysis requests logged
- User attribution when available
- Retention period: 365 days

### Network Security

```
┌────────────────────────────────────────┐
│          External Network              │
│                                        │
│  ┌──────────────────────────────┐    │
│  │    Kibana (authenticated)    │    │
│  └──────────────────────────────┘    │
└────────────┬───────────────────────────┘
             │ (HTTPS/TLS)
┌────────────┴───────────────────────────┐
│       Internal Network                 │
│  ┌──────────────┐  ┌───────────────┐ │
│  │ Elasticsearch│  │  LLM Service  │ │
│  │   (Cloud)    │  │  (Internal)   │ │
│  └──────────────┘  └───────────────┘ │
│         ↑                  ↑          │
│         └──────────────────┘          │
│              Apache NiFi              │
└───────────────────────────────────────┘
```

## Scalability Considerations

### Elasticsearch

- **Sharding**: 2 shards per index (hot tier)
- **Replicas**: 1 replica for high availability
- **ILM**: Automatic rollover and lifecycle management
- **Storage**: Approximately 100GB per month (typical deployment)

### ML Jobs

- **Model Memory**: 256-512MB per job
- **Datafeeds**: 5-minute to 1-hour intervals
- **Forecast Jobs**: Run on-demand or scheduled

### LLM Service

- **Workers**: 4 Gunicorn workers (default)
- **Timeout**: 120 seconds per request
- **Rate Limiting**: Configure at load balancer
- **Caching**: Not implemented (stateless service)

## Monitoring the Monitoring

### Key Metrics

- ML job execution time
- Transform lag
- LLM service response time
- Dashboard load time
- Elasticsearch query performance

### Health Checks

- `/health` endpoint on LLM service
- ML job status via `_ml/anomaly_detectors/_stats`
- Transform status via `_transform/_stats`
- Index write rate monitoring

## Future Enhancements

- Multi-cluster aggregation
- Custom ML models for specific workloads
- Advanced cost optimization recommendations
- Integration with ITSM tools (ServiceNow, Jira)
- Mobile dashboard application
