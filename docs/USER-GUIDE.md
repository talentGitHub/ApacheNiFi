# NiFi Observability Platform - User Guide

This guide helps you use the NiFi Observability Platform effectively for monitoring, troubleshooting, and optimizing your Apache NiFi deployments.

## Dashboard Navigation

### 1. Executive Overview Dashboard

**Purpose**: Single-pane-of-glass view for stakeholders  
**Refresh Rate**: 30 seconds  
**Best For**: Daily standup meetings, executive briefings, NOC displays

#### Key Panels

- **System Status KPI**: Current count of active ERROR bulletins
- **Active Errors (Last 5 min)**: Recent error breakdown by source
- **JVM Memory Utilization**: Gauge showing current heap usage with 85% threshold
- **Queue Backpressure Gauge**: Average queue utilization across all connections
- **Error Rate Timeline**: Stacked area chart showing ERROR and WARN trends
- **Processor Health Heatmap**: Processing time by processor type over time

#### How to Use

1. **Green/Healthy**: System Status KPI shows 0-5 errors → Normal operations
2. **Yellow/Warning**: JVM Memory >70% or Queue Backpressure >60% → Monitor closely
3. **Red/Critical**: System Status KPI >10 errors or Memory >85% → Immediate action required

#### Common Actions

- **High Memory**: Click gauge → Drill down to System Diagnostics dashboard
- **Queue Issues**: Click backpressure gauge → Go to Flow Performance dashboard
- **Error Spike**: Click error timeline → Navigate to Bulletin Deep Dive

---

### 2. Bulletin Deep Dive Dashboard

**Purpose**: Comprehensive error analysis and troubleshooting  
**Best For**: Incident investigation, root cause analysis

#### Key Panels

- **Bulletins Over Time**: Stacked bar chart (ERROR/WARN/INFO)
- **Top 10 Error Messages**: Most frequent errors with counts
- **Error Distribution by Category**: Donut chart of error types
- **Time-based Patterns**: Heatmap showing errors by hour and day of week
- **Live Bulletin Stream**: Real-time searchable table

#### Investigation Workflow

1. **Identify Pattern**: Look at "Bulletins Over Time" for spikes
2. **Find Root Cause**: Check "Top 10 Error Messages" for common issues
3. **Categorize**: Review "Error Distribution" to understand error types
4. **Search Details**: Use "Live Bulletin Stream" with filters:
   ```
   bulletinLevel: ERROR AND bulletinSourceName: "YourProcessor"
   ```

#### Common Error Categories

- **PORT_CONFLICT**: "Address already in use" errors
- **MEMORY_ERROR**: OutOfMemoryError, heap issues
- **CONNECTION_ERROR**: Connection refused, timeouts
- **VALIDATION_ERROR**: Invalid configuration
- **CACHE_SERVER_ERROR**: DistributedMapCacheServer failures

#### Pro Tips

- **Time Patterns**: If errors cluster at specific hours, check scheduled jobs
- **Source Correlation**: Multiple processors failing? Check shared resources (DB, API)
- **Message Analysis**: Click error message → See all related bulletins

---

### 3. System Diagnostics Health Dashboard

**Purpose**: JVM, memory, storage, and GC monitoring  
**Best For**: Performance tuning, capacity planning, memory optimization

#### Key Panels

- **Heap Usage Gauge**: Current heap utilization percentage
- **Non-Heap Usage Gauge**: Metaspace and code cache usage
- **GC Performance**: Garbage collection count rate and duration
- **Storage Utilization**: Usage by repository (content, flowfile, provenance)
- **CPU Load Average**: System processor load
- **Thread Metrics**: Total and daemon threads over time
- **Historical Comparison Table**: Hourly metrics comparison

#### Health Thresholds

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Heap Usage | < 70% | 70-85% | > 85% |
| GC Pause | < 200ms | 200-500ms | > 500ms |
| Storage | < 70% | 70-85% | > 85% |
| CPU Load | < 70% | 70-90% | > 90% |

#### Optimization Actions

**High Heap Usage (>85%)**:
1. Check "Historical Comparison" for trends
2. Review GC Performance → If high GC time, tune JVM
3. Analyze Flow Performance → Identify memory-heavy processors

**Storage Issues**:
1. Review "Storage Utilization" by repository
2. Content Repository full? Increase cleanup frequency
3. Provenance full? Reduce retention period

**GC Pause Time High**:
1. Check heap size → May need to increase `-Xmx`
2. Review GC algorithm → Consider G1GC
3. Analyze allocation patterns → Optimize processor config

---

### 4. Flow Performance Analytics Dashboard

**Purpose**: Processor and connection performance optimization  
**Best For**: Performance bottleneck identification, throughput analysis

#### Key Panels

- **Throughput Trends**: Read/write/transfer rates over time
- **Top Processors by Processing Time**: Slowest processors
- **Processor Statistics Table**: Detailed metrics per processor
- **Queue Backpressure Monitoring**: Queue utilization by connection
- **Connection Details**: Queue size, backpressure thresholds
- **Record Processing Metrics**: Record counts and rates

#### Performance Analysis

**Finding Bottlenecks**:
1. Check "Top Processors by Processing Time"
2. Look for processors with:
   - High average processing time
   - Low invocation count (underutilized)
   - High queue counts (backlogged)

**Optimization Strategies**:

**Slow Processor** (high processing time):
- Increase concurrent tasks
- Optimize processor configuration
- Consider batching

**Queue Backpressure** (>80% utilization):
- Increase queue size
- Scale up downstream processors
- Add more threads to consumer

**Low Throughput**:
- Check run schedule → May be throttled
- Review batch size → Increase for better performance
- Verify processor state → Should be "Running"

#### KQL Query Examples

```
# Find invalid processors
runStatus: Invalid

# High queue utilization
queueUtilizationPercent > 80

# Slow processors
processingNanos > 10000000000
```

---

### 5. Multi-Environment Overview Dashboard

**Purpose**: Cross-site comparative monitoring  
**Best For**: Multi-datacenter operations, environment comparison

#### Key Panels

- **Environment Health Cards**: Status by environment (prod, staging, dev)
- **Throughput Comparison**: Bytes transferred by environment
- **Cross-Environment Error Rate**: Error counts across sites
- **Resource Utilization**: Radar chart of CPU/Memory/Storage by environment

#### Use Cases

**Comparing Environments**:
- Prod vs Staging → Verify parity
- US-East vs US-West → Load distribution
- Day vs Night shifts → Usage patterns

**Health Monitoring**:
- Green cards → Healthy
- Yellow cards → Degraded
- Red cards → Critical issues

**Capacity Planning**:
- Compare throughput trends
- Identify overloaded environments
- Plan resource allocation

---

### 6. Historical Trends & Capacity Planning Dashboard

**Purpose**: Long-term analysis and forecasting  
**Best For**: Capacity planning, SLA compliance, budget forecasting

#### Key Panels

- **Data Processing Volume Growth**: 30-day ML forecast
- **Storage Growth Projection**: Predicted storage needs
- **Capacity Projections Table**: Future resource requirements
- **Processor Duration Distribution**: Processing time histogram
- **SLA Compliance Goal**: Percentage meeting SLA

#### Capacity Planning Workflow

1. **Review 30-Day Forecast**: Check predicted growth
2. **Storage Projection**: When will storage be full?
3. **Resource Requirements**: CPU/Memory/Storage needs
4. **Budget Planning**: Cost estimates for scaling

#### ML Forecast Interpretation

- **Confidence Bands**: Shaded area shows prediction range
- **Trend Line**: Expected growth trajectory
- **Anomalies**: Marked with annotations

**Green Forecast**: Capacity sufficient for 90+ days  
**Yellow Forecast**: Capacity sufficient for 30-90 days  
**Red Forecast**: Capacity critical within 30 days

---

### 7. Specific Error Analysis Dashboard

**Purpose**: Deep dive into critical error patterns  
**Best For**: Troubleshooting specific issues, cascading failure analysis

#### Key Panels

- **Port Binding Issues**: "Address already in use" errors
- **DistributedMapCacheServer Failures**: Cache service errors
- **Cascading Failure Analysis**: Sankey diagram showing error propagation
- **Error Timeline by Category**: Temporal error patterns
- **Affected Components**: Components impacted by errors

#### Common Issues

**Port Binding Conflict**:
1. Identify port number in error message
2. Check "Affected Components" → Which service?
3. Run remediation → Kill conflicting process
4. Restart NiFi controller service

**Cache Server Failures**:
1. Check error timeline → Recurring pattern?
2. Review system diagnostics → Memory issue?
3. Verify cache configuration
4. Consider increasing cache memory

**Cascading Failures**:
1. Use Sankey diagram → Trace error flow
2. Identify root component → Fix source
3. Restart downstream components
4. Monitor recovery

---

## Common Workflows

### Workflow 1: Incident Response

1. **Alert Received** → Open Executive Overview
2. **Identify Issue** → Check error count and memory
3. **Deep Dive** → Navigate to Bulletin Deep Dive
4. **Find Root Cause** → Review top errors and patterns
5. **Check Context** → Open System Diagnostics
6. **Remediate** → Execute fix, monitor recovery
7. **Document** → Record in incident log

### Workflow 2: Performance Optimization

1. **Baseline** → Review Flow Performance Analytics
2. **Identify Bottlenecks** → Top processors by time
3. **Analyze Queues** → Check backpressure
4. **Optimize** → Tune processor configuration
5. **Validate** → Monitor throughput trends
6. **Document** → Record optimizations

### Workflow 3: Capacity Planning

1. **Historical Analysis** → Review Trends dashboard
2. **Forecast** → Check ML predictions
3. **Resource Planning** → Calculate needs
4. **Budget Approval** → Present forecast to management
5. **Implementation** → Scale resources
6. **Validation** → Verify capacity sufficient

---

## Tips & Best Practices

### Dashboard Tips

- **Pin Frequently Used**: Star your most-used dashboards
- **Time Range**: Adjust based on analysis (last 15m for troubleshooting, 30d for trends)
- **Refresh Rate**: Set to 30s for monitoring, pause for detailed analysis
- **Filters**: Use environment/cluster filters for focused view

### KQL Query Tips

```
# Multiple conditions
bulletinLevel: ERROR AND environment: production

# Range queries
heapUtilization >= 80

# Wildcards
bulletinMessage: *timeout*

# Exists
_exists_: errorCategory

# NOT operator
NOT bulletinLevel: INFO
```

### Alert Best Practices

- **Tune Thresholds**: Adjust based on your baseline
- **Reduce Noise**: Consolidate related alerts
- **Escalation**: P1 → PagerDuty, P3 → Email
- **Acknowledgment**: Always ack alerts to track ownership

### ML Job Monitoring

- **Check Daily**: Review anomaly scores
- **Tune Sensitivity**: Adjust based on false positives
- **Model Training**: Let ML jobs run 1-2 weeks for good baseline
- **Annotations**: Add context to anomalies for future reference

---

## Keyboard Shortcuts

- **Ctrl+/** or **Cmd+/**: Open command palette
- **Ctrl+K** or **Cmd+K**: Quick search
- **Esc**: Close modal/panel
- **Tab**: Navigate fields
- **Enter**: Apply filter/query

---

## Getting Help

### Documentation

- **Deployment Guide**: `docs/DEPLOYMENT-GUIDE.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **API Reference**: `docs/API-REFERENCE.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Q&A and community help
- **Email**: support@your-company.com

---

**Happy Monitoring!** 🚀
