# Troubleshooting Guide

## Common Issues and Solutions

### Elasticsearch Issues

#### Issue: Cannot connect to Elasticsearch

**Symptoms**:
- Scripts fail with connection errors
- "Connection refused" messages
- Timeouts during API calls

**Solutions**:

1. **Verify credentials**:
```bash
# Test connection
curl -X GET "https://your-es-endpoint.es.io/" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

2. **Check Cloud ID format**:
```yaml
# Should be: deployment-name:base64-encoded-string
cloud_id: "my-deployment:dXMtY2VudHJhbD..."
```

3. **Verify API key**:
- Go to Elasticsearch Cloud console
- Navigate to Management → API Keys
- Ensure key has not expired
- Create new key if necessary

4. **Check network connectivity**:
```bash
# Test DNS resolution
nslookup your-deployment.es.io

# Test connectivity
telnet your-deployment.es.io 9243
```

#### Issue: Index templates not being applied

**Symptoms**:
- Data ingested without proper mappings
- Missing fields in documents
- Incorrect field types

**Solutions**:

1. **Verify template priority**:
```bash
curl -X GET "${ES_URL}/_index_template/nifi-bulletins" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
# Check "priority" field - should be 200+
```

2. **Check index patterns**:
```bash
# Template should match: nifi-bulletins-*
# Actual index should be: nifi-bulletins-000001
```

3. **Delete and recreate index**:
```bash
# Only if data is test/development!
curl -X DELETE "${ES_URL}/nifi-bulletins-000001" \
  -H "Authorization: ApiKey ${ES_API_KEY}"

./scripts/setup-elasticsearch.sh
```

#### Issue: ILM policy not executing

**Symptoms**:
- Old data not being deleted
- Indices not rolling over
- Storage growing unexpectedly

**Solutions**:

1. **Check ILM status**:
```bash
curl -X GET "${ES_URL}/_ilm/status" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
# Should show: "operation_mode": "RUNNING"
```

2. **Verify policy is attached**:
```bash
curl -X GET "${ES_URL}/nifi-bulletins-*/_settings" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
# Check for "index.lifecycle.name"
```

3. **Manual rollover if stuck**:
```bash
curl -X POST "${ES_URL}/nifi-bulletins/_rollover" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

4. **Check ILM explain**:
```bash
curl -X GET "${ES_URL}/nifi-bulletins-*/_ilm/explain" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

### Kibana Issues

#### Issue: Dashboards not loading

**Symptoms**:
- Blank dashboard screens
- "Could not find index pattern" errors
- Visualization errors

**Solutions**:

1. **Verify index patterns exist**:
```
Kibana → Stack Management → Data Views
```

2. **Check for data**:
```bash
curl -X GET "${ES_URL}/nifi-bulletins-*/_search?size=1" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Recreate data views**:
```bash
./scripts/setup-kibana.sh
```

4. **Clear browser cache**:
- Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- Clear cookies for Kibana domain

#### Issue: Dashboard shows "No results found"

**Symptoms**:
- Dashboard panels empty
- Time range shows no data
- Queries return 0 hits

**Solutions**:

1. **Check time range**:
- Adjust to "Last 7 days" or "Last 30 days"
- Ensure data exists in selected range

2. **Verify data ingestion**:
```bash
# Check document count
curl -X GET "${ES_URL}/nifi-bulletins-*/_count" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Check filters**:
- Remove all dashboard filters
- Check saved search filters
- Verify index pattern

4. **Refresh field list**:
```
Data View settings → Refresh field list
```

### Machine Learning Issues

#### Issue: ML jobs not starting

**Symptoms**:
- Job status shows "closed"
- "Cannot open job" errors
- Datafeeds not starting

**Solutions**:

1. **Check if indices have data**:
```bash
curl -X GET "${ES_URL}/nifi-flow-performance-*/_count" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
# Need at least some data for ML jobs to start
```

2. **Check job status**:
```bash
curl -X GET "${ES_URL}/_ml/anomaly_detectors/nifi-processing-anomaly/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Try opening job manually**:
```bash
curl -X POST "${ES_URL}/_ml/anomaly_detectors/nifi-processing-anomaly/_open" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

4. **Check datafeed configuration**:
```bash
curl -X GET "${ES_URL}/_ml/datafeeds/datafeed-nifi-processing-anomaly" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

5. **Increase model memory limit**:
```bash
# Edit ML job definition
# Increase "model_memory_limit" from 256mb to 512mb
```

#### Issue: Transforms not processing

**Symptoms**:
- Transform status shows "stopped"
- Destination index empty
- No errors shown

**Solutions**:

1. **Check transform status**:
```bash
curl -X GET "${ES_URL}/_transform/nifi-hourly-processor-performance/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

2. **Start transform**:
```bash
curl -X POST "${ES_URL}/_transform/nifi-hourly-processor-performance/_start" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Check source index has data**:
```bash
curl -X GET "${ES_URL}/nifi-flow-performance-*/_count" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

4. **Review transform definition**:
- Verify pivot configuration
- Check aggregation syntax
- Confirm sync settings

### LLM Service Issues

#### Issue: Service not responding

**Symptoms**:
- Connection refused errors
- Timeout on health endpoint
- 500 Internal Server Error

**Solutions**:

1. **Check if service is running**:
```bash
# For Docker
docker ps | grep nifi-llm-service

# For Python
ps aux | grep app.py
```

2. **Check service logs**:
```bash
# Docker
docker logs nifi-llm-service

# Python
# Check console output
```

3. **Restart service**:
```bash
# Docker
docker restart nifi-llm-service

# Python
cd services/llm-analysis-service
python app.py
```

4. **Verify environment variables**:
```bash
# Check .env file
cat services/llm-analysis-service/.env
# Ensure ES_CLOUD_ID, ES_API_KEY, LLM_API_KEY are set
```

#### Issue: LLM API key invalid

**Symptoms**:
- "Invalid API key" errors
- 401 Unauthorized responses
- "Rate limit exceeded" messages

**Solutions**:

1. **Verify API key**:
```bash
# For OpenAI
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# For Anthropic
curl https://api.anthropic.com/v1/complete \
  -H "x-api-key: YOUR_API_KEY"
```

2. **Check API key format**:
- OpenAI: Starts with "sk-"
- Anthropic: Starts with "sk-ant-"
- Azure: Different format

3. **Update .env file**:
```bash
cd services/llm-analysis-service
nano .env
# Update LLM_API_KEY
docker restart nifi-llm-service
```

4. **Check rate limits**:
- Review API usage dashboard
- Consider upgrading plan
- Implement request throttling

#### Issue: Analysis returns errors

**Symptoms**:
- "Bulletin not found" errors
- Incomplete analysis
- Timeout errors

**Solutions**:

1. **Verify bulletin exists**:
```bash
curl -X GET "${ES_URL}/nifi-bulletins-*/_search" \
  -H "Authorization: ApiKey ${ES_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"query":{"term":{"bulletinId":"YOUR_BULLETIN_ID"}}}'
```

2. **Check Elasticsearch connection from service**:
```bash
docker exec -it nifi-llm-service curl -X GET "${ES_URL}/" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Increase timeout**:
- Edit LLM service configuration
- Increase request timeout values

### NiFi Integration Issues

#### Issue: Data not appearing in Elasticsearch

**Symptoms**:
- NiFi processors running
- But no data in Elasticsearch indices
- PutElasticsearch shows success

**Solutions**:

1. **Check PutElasticsearch configuration**:
- Verify Cloud ID and API key
- Confirm index name matches template pattern
- Check if pipeline is specified

2. **Verify ingest pipeline**:
```bash
curl -X GET "${ES_URL}/_ingest/pipeline/nifi-bulletins-enrichment" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

3. **Check NiFi bulletin board**:
- Look for Elasticsearch connection errors
- Check for authentication failures
- Review processor logs

4. **Test with curl**:
```bash
curl -X POST "${ES_URL}/nifi-bulletins-000001/_doc?pipeline=nifi-bulletins-enrichment" \
  -H "Authorization: ApiKey ${ES_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "bulletinLevel": "ERROR",
    "bulletinMessage": "Test message",
    "@timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"
  }'
```

#### Issue: Auto-remediation not triggering

**Symptoms**:
- Errors occur but no remediation
- Self-healing flows not running
- No audit entries

**Solutions**:

1. **Verify template imported**:
- Check NiFi UI for self-healing flow
- Ensure processors are started

2. **Check bulletin monitoring**:
- Verify InvokeHTTP processor connecting to NiFi API
- Check scheduling (should be 10 seconds)

3. **Review RouteOnContent configuration**:
- Verify search patterns are correct
- Check relationship routing

4. **Test audit logging**:
- Manually trigger flow
- Check `nifi-remediation-audit` index

### Performance Issues

#### Issue: Slow dashboard loading

**Symptoms**:
- Dashboards take >10 seconds to load
- Timeout errors
- Browser becomes unresponsive

**Solutions**:

1. **Reduce time range**:
- Use "Last 24 hours" instead of "Last 30 days"
- Implement time-based filters

2. **Optimize queries**:
- Add filters to reduce data scanned
- Use cached queries where possible

3. **Check Elasticsearch performance**:
```bash
curl -X GET "${ES_URL}/_cluster/health" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
# Check status and active shards
```

4. **Consider data sampling**:
- Use sampling in visualizations
- Aggregate data for historical views

#### Issue: High Elasticsearch storage usage

**Symptoms**:
- Storage fills up quickly
- Costs increasing
- Performance degradation

**Solutions**:

1. **Check ILM policies**:
```bash
curl -X GET "${ES_URL}/_ilm/policy" \
  -H "Authorization: ApiKey ${ES_API_KEY}"
```

2. **Adjust retention periods**:
- Edit ILM policy delete phase
- Reduce from 90 days to 30 days if needed

3. **Enable force merge**:
- Already configured in warm phase
- Reduces segment count

4. **Review collection frequency**:
- Reduce bulletins from 10s to 30s
- Reduce system diagnostics from 1m to 5m

## Diagnostic Commands

### Quick Health Check

```bash
# Elasticsearch cluster health
curl -X GET "${ES_URL}/_cluster/health" \
  -H "Authorization: ApiKey ${ES_API_KEY}"

# Index statistics
curl -X GET "${ES_URL}/_cat/indices/nifi-*?v" \
  -H "Authorization: ApiKey ${ES_API_KEY}"

# ML job status
curl -X GET "${ES_URL}/_ml/anomaly_detectors/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"

# Transform status
curl -X GET "${ES_URL}/_transform/_stats" \
  -H "Authorization: ApiKey ${ES_API_KEY}"

# LLM service health
curl http://localhost:5000/health
```

### Log Collection

```bash
# Export Elasticsearch logs
# (via Cloud console)

# Kibana logs
# (via Cloud console)

# LLM service logs
docker logs nifi-llm-service > llm-service.log 2>&1

# NiFi logs
tail -n 1000 /path/to/nifi/logs/nifi-app.log > nifi.log
```

## Getting Additional Help

### Support Channels

1. **GitHub Issues**: https://github.com/talentGitHub/ApacheNiFi/issues
2. **Email Support**: support@your-company.com
3. **Community Discussions**: https://github.com/talentGitHub/ApacheNiFi/discussions

### Information to Provide

When seeking help, include:
- Description of the issue
- Steps to reproduce
- Error messages and logs
- Version information
- Environment details (Elasticsearch version, NiFi version, etc.)
- Screenshots if applicable

### Useful Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
- [Project README](../README.md)
- [Deployment Guide](DEPLOYMENT-GUIDE.md)
- [Architecture](ARCHITECTURE.md)

---

**Document Version**: 1.0.0  
**Last Updated**: 2026-01-28
