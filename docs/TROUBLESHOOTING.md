# Troubleshooting Guide

Common issues and solutions for the Apache NiFi Observability Platform.

## Common Issues

### 1. Elasticsearch Connection Failed

**Symptom**: Scripts fail with "Failed to connect to Elasticsearch"

**Solutions**:
```bash
# Verify credentials
cat config/elasticsearch-cloud.yaml

# Test connection manually
curl -X GET "$ES_HOST" -H "Authorization: ApiKey $ES_API_KEY"

# Check network connectivity
ping your-elasticsearch-host.es.io

# Verify firewall rules allow outbound HTTPS (port 443)
```

**Common Causes**:
- Incorrect API key or password
- Firewall blocking port 443
- Expired API key
- Wrong Elasticsearch URL

### 2. Kibana Dashboards Not Loading

**Symptom**: Dashboards show "No results found"

**Solutions**:
```bash
# Verify data is in Elasticsearch
curl -X GET "$ES_HOST/nifi-bulletins-*/_count"

# Check index patterns
curl -X GET "$KIBANA_HOST/api/saved_objects/index-pattern" \
  -H "kbn-xsrf: true"

# Verify time range in dashboard
# Make sure it covers the period when data was ingested
```

### 3. ML Jobs Not Running

**Symptom**: ML jobs show as "stopped" or "failed"

**Solutions**:
```bash
# Check ML job status
curl -X GET "$ES_HOST/_ml/anomaly_detectors/_stats"

# View error messages
curl -X GET "$ES_HOST/_ml/anomaly_detectors/nifi-processing-anomaly/_stats"

# Restart ML job
curl -X POST "$ES_HOST/_ml/anomaly_detectors/nifi-processing-anomaly/_open"
curl -X POST "$ES_HOST/_ml/datafeeds/datafeed-nifi-processing-anomaly/_start"
```

**Common Causes**:
- Insufficient model memory
- No data in source indices
- Datafeed query returns no results
- ML node not available

### 4. LLM Service Not Responding

**Symptom**: `/health` endpoint times out or returns errors

**Solutions**:
```bash
# Check Docker container status
docker ps | grep nifi-llm-service

# View container logs
docker logs nifi-llm-service

# Restart service
docker restart nifi-llm-service

# Verify environment variables
docker exec nifi-llm-service env | grep -E "ELASTICSEARCH|LLM"
```

**Common Causes**:
- Missing API keys in .env file
- Elasticsearch connection issues
- LLM provider API errors
- Insufficient container resources

### 5. Transforms Not Processing

**Symptom**: Transform status shows "stopped" or destination indices empty

**Solutions**:
```bash
# Check transform status
curl -X GET "$ES_HOST/_transform/_stats"

# View specific transform
curl -X GET "$ES_HOST/_transform/nifi-hourly-processor-performance/_stats"

# Start transform
curl -X POST "$ES_HOST/_transform/nifi-hourly-processor-performance/_start"

# Check for errors
curl -X GET "$ES_HOST/_transform/nifi-hourly-processor-performance" | jq '.transforms[0].health'
```

**Common Causes**:
- Source indices have no data
- Transform query returns no results
- Insufficient permissions
- Destination index locked or read-only

### 6. NiFi Not Sending Data

**Symptom**: No data appearing in Elasticsearch

**Solutions**:
```bash
# Check NiFi processor status (via UI or API)
curl "http://localhost:8080/nifi-api/process-groups/root/status"

# Verify bulletin queue
curl "http://localhost:8080/nifi-api/flow/bulletin-board"

# Check NiFi logs
tail -f /var/log/nifi/nifi-app.log
```

**Common Causes**:
- NiFi processors stopped
- Network connectivity issues
- Elasticsearch authentication failures
- Queue backpressure

### 7. High Memory Usage in Elasticsearch

**Symptom**: Elasticsearch performance degraded, high heap usage

**Solutions**:
```bash
# Check index sizes
curl -X GET "$ES_HOST/_cat/indices/nifi-*?v&h=index,store.size"

# Force merge old indices
curl -X POST "$ES_HOST/nifi-bulletins-2026.01.01-000001/_forcemerge?max_num_segments=1"

# Trigger ILM manually
curl -X POST "$ES_HOST/nifi-bulletins-*/_ilm/retry"

# Review ILM status
curl -X GET "$ES_HOST/_ilm/status"
```

## Error Messages

### "Pipeline not found"

**Error**: `Pipeline with id [nifi-bulletins-pipeline] does not exist`

**Solution**: Run `./scripts/setup-elasticsearch.sh` again to recreate pipelines

### "Index template already exists"

**Warning**: This is normal when re-running setup scripts. Templates are not recreated.

### "ML job already exists"

**Warning**: Normal when re-running ML deployment. Job is not modified.

### "Datafeed already started"

**Warning**: Normal, indicates datafeed is already running.

### "Authentication failed"

**Error**: Invalid credentials

**Solution**: Verify API key or username/password in config file

## Performance Issues

### Slow Dashboard Load Times

1. Reduce time range in dashboard
2. Increase Elasticsearch heap size
3. Add more Elasticsearch nodes
4. Optimize Kibana queries
5. Use dashboard caching

### High Elasticsearch Query Latency

1. Check shard allocation
2. Review index mapping
3. Optimize Painless scripts in pipelines
4. Use doc values for aggregations
5. Increase `refresh_interval`

### LLM Service Timeouts

1. Increase timeout in app configuration
2. Use faster LLM model (e.g., GPT-3.5-turbo instead of GPT-4)
3. Reduce context size sent to LLM
4. Scale to multiple service instances
5. Implement request caching

## Debugging Commands

```bash
# View all indices
curl -X GET "$ES_HOST/_cat/indices/nifi-*?v"

# Check ILM status
curl -X GET "$ES_HOST/nifi-*/_ilm/explain"

# View ML job details
curl -X GET "$ES_HOST/_ml/anomaly_detectors/nifi-processing-anomaly"

# Check transform stats
curl -X GET "$ES_HOST/_transform/nifi-*/_stats"

# View pipeline definition
curl -X GET "$ES_HOST/_ingest/pipeline/nifi-bulletins-pipeline"

# Test pipeline
curl -X POST "$ES_HOST/_ingest/pipeline/nifi-bulletins-pipeline/_simulate" \
  -H "Content-Type: application/json" \
  -d '{"docs":[{"_source":{"bulletinLevel":"ERROR","bulletinMessage":"test"}}]}'
```

## Getting Help

1. Check logs: `docker logs nifi-llm-service`
2. Run verification: `./scripts/verify-deployment.sh`
3. Review Elasticsearch logs in Kibana
4. Search GitHub issues
5. Contact support team

## Preventive Maintenance

### Weekly

- Review ML job performance
- Check ILM policy effectiveness
- Validate dashboard accuracy
- Review error patterns

### Monthly

- Audit user access
- Review retention policies
- Update ML models
- Optimize dashboard queries
- Check disk usage trends

### Quarterly

- Review and update alerting rules
- Performance tuning
- Capacity planning
- Security audit
