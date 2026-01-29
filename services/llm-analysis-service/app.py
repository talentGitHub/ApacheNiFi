"""
NiFi LLM Analysis Service
Provides AI-powered root cause analysis and remediation recommendations
"""

from flask import Flask, request, jsonify
from datetime import datetime
import os
import json
from elasticsearch import Elasticsearch
import openai
import anthropic
from config import Config

app = Flask(__name__)
config = Config()

# Initialize Elasticsearch client
es = None
if config.ES_CLOUD_ID and config.ES_API_KEY:
    es = Elasticsearch(
        cloud_id=config.ES_CLOUD_ID,
        api_key=config.ES_API_KEY
    )

# Initialize LLM clients
openai_client = None
anthropic_client = None

if config.OPENAI_API_KEY:
    openai.api_key = config.OPENAI_API_KEY
    openai_client = openai

if config.ANTHROPIC_API_KEY:
    anthropic_client = anthropic.Anthropic(api_key=config.ANTHROPIC_API_KEY)


def get_bulletin_context(bulletin_id):
    """Fetch bulletin and related context from Elasticsearch"""
    if not es:
        return None
    
    try:
        # Get the specific bulletin
        bulletin_result = es.search(
            index="nifi-bulletins-*",
            body={
                "query": {
                    "term": {
                        "bulletinId": bulletin_id
                    }
                },
                "size": 1
            }
        )
        
        if not bulletin_result['hits']['hits']:
            return None
        
        bulletin = bulletin_result['hits']['hits'][0]['_source']
        
        # Get recent system diagnostics
        system_diag = es.search(
            index="nifi-system-diagnostics-*",
            body={
                "query": {
                    "range": {
                        "@timestamp": {
                            "gte": "now-10m"
                        }
                    }
                },
                "size": 1,
                "sort": [{"@timestamp": "desc"}]
            }
        )
        
        # Get related bulletins (same source, recent)
        related_bulletins = es.search(
            index="nifi-bulletins-*",
            body={
                "query": {
                    "bool": {
                        "must": [
                            {"term": {"bulletinSourceName": bulletin.get('bulletinSourceName')}},
                            {"range": {"@timestamp": {"gte": "now-1h"}}}
                        ]
                    }
                },
                "size": 10
            }
        )
        
        return {
            "bulletin": bulletin,
            "system_diagnostics": system_diag['hits']['hits'][0]['_source'] if system_diag['hits']['hits'] else None,
            "related_bulletins": [hit['_source'] for hit in related_bulletins['hits']['hits']],
            "related_count": related_bulletins['hits']['total']['value']
        }
    except Exception as e:
        print(f"Error fetching context: {e}")
        return None


def analyze_with_openai(context):
    """Analyze bulletin using OpenAI GPT-4"""
    if not openai_client:
        return None
    
    bulletin = context['bulletin']
    system_diag = context.get('system_diagnostics', {})
    
    prompt = f"""Analyze this Apache NiFi error and provide root cause analysis and remediation steps.

Error Details:
- Level: {bulletin.get('bulletinLevel')}
- Message: {bulletin.get('bulletinMessage')}
- Source: {bulletin.get('bulletinSourceName')} ({bulletin.get('bulletinSourceType')})
- Category: {bulletin.get('errorCategory')}
- Time: {bulletin.get('@timestamp')}

System Context:
- Heap Utilization: {system_diag.get('heapUtilization', 'N/A')}%
- CPU Load: {system_diag.get('processorLoadAverage', 'N/A')}
- Total Threads: {system_diag.get('totalThreads', 'N/A')}

Related Issues: {context['related_count']} similar bulletins in the last hour

Provide:
1. Root Cause Analysis (concise explanation)
2. Immediate Actions (3-5 actionable steps)
3. Prevention Strategies (long-term solutions)
4. Impact Assessment (High/Medium/Low with justification)
5. Confidence Score (0.0-1.0)

Format response as JSON with keys: root_cause, immediate_actions (array), prevention (array), impact, confidence"""

    try:
        response = openai.chat.completions.create(
            model=config.LLM_MODEL,
            messages=[
                {"role": "system", "content": "You are an expert Apache NiFi administrator and troubleshooter."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        print(f"OpenAI analysis error: {e}")
        return None


def analyze_with_anthropic(context):
    """Analyze bulletin using Anthropic Claude"""
    if not anthropic_client:
        return None
    
    bulletin = context['bulletin']
    system_diag = context.get('system_diagnostics', {})
    
    prompt = f"""Analyze this Apache NiFi error and provide root cause analysis and remediation steps.

Error Details:
- Level: {bulletin.get('bulletinLevel')}
- Message: {bulletin.get('bulletinMessage')}
- Source: {bulletin.get('bulletinSourceName')} ({bulletin.get('bulletinSourceType')})
- Category: {bulletin.get('errorCategory')}
- Time: {bulletin.get('@timestamp')}

System Context:
- Heap Utilization: {system_diag.get('heapUtilization', 'N/A')}%
- CPU Load: {system_diag.get('processorLoadAverage', 'N/A')}
- Total Threads: {system_diag.get('totalThreads', 'N/A')}

Related Issues: {context['related_count']} similar bulletins in the last hour

Provide:
1. Root Cause Analysis (concise explanation)
2. Immediate Actions (3-5 actionable steps)
3. Prevention Strategies (long-term solutions)
4. Impact Assessment (High/Medium/Low with justification)
5. Confidence Score (0.0-1.0)

Format response as JSON with keys: root_cause, immediate_actions (array), prevention (array), impact, confidence"""

    try:
        message = anthropic_client.messages.create(
            model=config.LLM_MODEL,
            max_tokens=2000,
            temperature=0.3,
            system="You are an expert Apache NiFi administrator and troubleshooter.",
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        
        # Parse JSON from Claude's response
        content = message.content[0].text
        # Try to extract JSON if it's wrapped in markdown
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]
        
        return json.loads(content.strip())
    except Exception as e:
        print(f"Anthropic analysis error: {e}")
        return None


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "elasticsearch_connected": es is not None,
        "llm_provider": config.LLM_PROVIDER
    })


@app.route('/analyze', methods=['POST'])
def analyze_bulletin():
    """Analyze a bulletin and provide AI-powered insights"""
    data = request.get_json()
    
    if not data or 'bulletin_id' not in data:
        return jsonify({
            "error": "bulletin_id is required"
        }), 400
    
    bulletin_id = data['bulletin_id']
    
    # Fetch context from Elasticsearch
    context = get_bulletin_context(bulletin_id)
    
    if not context:
        return jsonify({
            "error": "Bulletin not found or Elasticsearch not configured"
        }), 404
    
    # Perform analysis based on configured LLM provider
    analysis = None
    if config.LLM_PROVIDER == 'openai':
        analysis = analyze_with_openai(context)
    elif config.LLM_PROVIDER == 'anthropic':
        analysis = analyze_with_anthropic(context)
    
    if not analysis:
        return jsonify({
            "error": "Analysis failed or LLM not configured"
        }), 500
    
    return jsonify({
        "bulletin_id": bulletin_id,
        "analysis": analysis,
        "timestamp": datetime.utcnow().isoformat(),
        "provider": config.LLM_PROVIDER
    })


@app.route('/remediate', methods=['POST'])
def trigger_remediation():
    """Webhook endpoint for auto-remediation triggers"""
    data = request.get_json()
    
    # Log the remediation trigger
    print(f"Remediation trigger received: {json.dumps(data, indent=2)}")
    
    # In a real implementation, this would trigger NiFi flows
    # or execute remediation scripts
    
    return jsonify({
        "status": "acknowledged",
        "alert_type": data.get('alert_type'),
        "timestamp": datetime.utcnow().isoformat()
    })


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    print(f"Starting NiFi LLM Analysis Service on port {port}")
    print(f"LLM Provider: {config.LLM_PROVIDER}")
    print(f"Elasticsearch Connected: {es is not None}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
