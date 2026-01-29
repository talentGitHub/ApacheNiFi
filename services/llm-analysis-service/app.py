"""
NiFi LLM Analysis Service

Root cause analysis and remediation recommendations for NiFi bulletins
using Large Language Models (OpenAI, Anthropic, Azure OpenAI)
"""

from flask import Flask, request, jsonify
from elasticsearch import Elasticsearch
from datetime import datetime, timedelta
import os
import json
import logging
from typing import Dict, List, Optional

# LLM Provider imports
try:
    import openai
    HAS_OPENAI = True
except ImportError:
    HAS_OPENAI = False

try:
    from anthropic import Anthropic
    HAS_ANTHROPIC = True
except ImportError:
    HAS_ANTHROPIC = False

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration from environment
ES_HOST = os.getenv('ELASTICSEARCH_HOST', 'http://localhost:9200')
ES_API_KEY = os.getenv('ELASTICSEARCH_API_KEY', '')
ES_USERNAME = os.getenv('ELASTICSEARCH_USERNAME', 'elastic')
ES_PASSWORD = os.getenv('ELASTICSEARCH_PASSWORD', '')

LLM_PROVIDER = os.getenv('LLM_PROVIDER', 'openai')  # openai, anthropic, azure
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-4-turbo')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
ANTHROPIC_MODEL = os.getenv('ANTHROPIC_MODEL', 'claude-3-sonnet-20240229')

# Initialize Elasticsearch client
if ES_API_KEY:
    es = Elasticsearch(
        [ES_HOST],
        api_key=ES_API_KEY,
        verify_certs=True
    )
else:
    es = Elasticsearch(
        [ES_HOST],
        basic_auth=(ES_USERNAME, ES_PASSWORD),
        verify_certs=False
    )

# Initialize LLM clients
llm_client = None
if LLM_PROVIDER == 'openai' and HAS_OPENAI and OPENAI_API_KEY:
    openai.api_key = OPENAI_API_KEY
    llm_client = 'openai'
    logger.info("Initialized OpenAI client")
elif LLM_PROVIDER == 'anthropic' and HAS_ANTHROPIC and ANTHROPIC_API_KEY:
    llm_client = Anthropic(api_key=ANTHROPIC_API_KEY)
    logger.info("Initialized Anthropic client")


def get_bulletin_context(bulletin_id: str) -> Optional[Dict]:
    """Retrieve bulletin and related context from Elasticsearch"""
    try:
        # Get the specific bulletin
        result = es.search(
            index="nifi-bulletins-*",
            query={"match": {"bulletinId": bulletin_id}},
            size=1
        )
        
        if not result['hits']['hits']:
            return None
        
        bulletin = result['hits']['hits'][0]['_source']
        
        # Get recent related bulletins (same source, last hour)
        related = es.search(
            index="nifi-bulletins-*",
            query={
                "bool": {
                    "must": [
                        {"match": {"bulletinSourceName": bulletin.get('bulletinSourceName')}},
                        {"range": {"@timestamp": {"gte": "now-1h"}}}
                    ]
                }
            },
            size=10,
            sort=[{"@timestamp": "desc"}]
        )
        
        # Get system diagnostics
        diagnostics = es.search(
            index="nifi-system-diagnostics-*",
            query={"range": {"@timestamp": {"gte": "now-15m"}}},
            size=5,
            sort=[{"@timestamp": "desc"}]
        )
        
        # Get performance metrics
        performance = es.search(
            index="nifi-flow-performance-*",
            query={
                "bool": {
                    "must": [
                        {"match": {"componentName": bulletin.get('bulletinSourceName')}},
                        {"range": {"@timestamp": {"gte": "now-1h"}}}
                    ]
                }
            },
            size=5,
            sort=[{"@timestamp": "desc"}]
        )
        
        return {
            "bulletin": bulletin,
            "related_bulletins": [hit['_source'] for hit in related['hits']['hits']],
            "system_diagnostics": [hit['_source'] for hit in diagnostics['hits']['hits']],
            "performance_metrics": [hit['_source'] for hit in performance['hits']['hits']]
        }
    
    except Exception as e:
        logger.error(f"Error fetching bulletin context: {e}")
        return None


def analyze_with_llm(context: Dict) -> Dict:
    """Analyze bulletin context using LLM"""
    
    bulletin = context['bulletin']
    
    # Build the prompt
    prompt = f"""You are an expert Apache NiFi troubleshooting assistant. Analyze the following error and provide actionable insights.

ERROR DETAILS:
- Level: {bulletin.get('bulletinLevel')}
- Message: {bulletin.get('bulletinMessage')}
- Source: {bulletin.get('bulletinSourceName')} ({bulletin.get('bulletinSourceType')})
- Category: {bulletin.get('errorCategory')}
- Timestamp: {bulletin.get('@timestamp')}

RECENT RELATED ERRORS ({len(context['related_bulletins'])}):
{json.dumps([b.get('bulletinMessage') for b in context['related_bulletins'][:3]], indent=2)}

SYSTEM HEALTH:
"""
    
    if context['system_diagnostics']:
        diag = context['system_diagnostics'][0]
        prompt += f"""
- Heap Utilization: {diag.get('heapUtilization', 'N/A')}%
- CPU Load: {diag.get('processorLoadAverage', 'N/A')}
- Total Threads: {diag.get('totalThreads', 'N/A')}
"""
    
    prompt += """

Please provide:
1. ROOT CAUSE: What is causing this error?
2. IMMEDIATE ACTIONS: What should be done right now? (3-5 specific steps)
3. PREVENTION: How to prevent this in the future? (3-5 recommendations)
4. IMPACT: What is the impact? (High/Medium/Low and why)
5. CONFIDENCE: Your confidence in this analysis (0.0-1.0)

Format your response as JSON with keys: root_cause, immediate_actions (array), prevention (array), impact, confidence
"""
    
    try:
        if llm_client == 'openai':
            response = openai.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": "You are an expert Apache NiFi troubleshooting assistant. Respond in JSON format."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            analysis_text = response.choices[0].message.content
            analysis = json.loads(analysis_text)
            
        elif isinstance(llm_client, Anthropic):
            response = llm_client.messages.create(
                model=ANTHROPIC_MODEL,
                max_tokens=2000,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3
            )
            analysis_text = response.content[0].text
            # Try to extract JSON from response
            if '```json' in analysis_text:
                analysis_text = analysis_text.split('```json')[1].split('```')[0]
            analysis = json.loads(analysis_text)
        else:
            # Fallback analysis
            analysis = {
                "root_cause": "LLM not configured - please check configuration",
                "immediate_actions": ["Configure LLM provider"],
                "prevention": ["Set up LLM API keys"],
                "impact": "Unable to analyze",
                "confidence": 0.0
            }
        
        return analysis
    
    except Exception as e:
        logger.error(f"Error in LLM analysis: {e}")
        return {
            "root_cause": f"Error during analysis: {str(e)}",
            "immediate_actions": ["Check bulletin message", "Review logs"],
            "prevention": ["Monitor system regularly"],
            "impact": "Unknown - analysis failed",
            "confidence": 0.0
        }


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "elasticsearch": es.ping(),
        "llm_provider": LLM_PROVIDER,
        "llm_configured": llm_client is not None
    })


@app.route('/analyze', methods=['POST'])
def analyze():
    """Analyze a bulletin and provide root cause analysis"""
    try:
        data = request.get_json()
        bulletin_id = data.get('bulletin_id')
        
        if not bulletin_id:
            return jsonify({"error": "bulletin_id is required"}), 400
        
        # Get bulletin context
        context = get_bulletin_context(bulletin_id)
        if not context:
            return jsonify({"error": "Bulletin not found"}), 404
        
        # Analyze with LLM
        analysis = analyze_with_llm(context)
        
        # Store analysis result
        analysis_doc = {
            "@timestamp": datetime.utcnow().isoformat(),
            "bulletin_id": bulletin_id,
            "analysis": analysis
        }
        
        es.index(
            index="nifi-analysis-results",
            document=analysis_doc
        )
        
        return jsonify({
            "bulletin_id": bulletin_id,
            "analysis": analysis,
            "timestamp": analysis_doc["@timestamp"]
        })
    
    except Exception as e:
        logger.error(f"Error in analyze endpoint: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/analyze/batch', methods=['POST'])
def analyze_batch():
    """Analyze multiple bulletins"""
    try:
        data = request.get_json()
        bulletin_ids = data.get('bulletin_ids', [])
        
        if not bulletin_ids:
            return jsonify({"error": "bulletin_ids array is required"}), 400
        
        results = []
        for bulletin_id in bulletin_ids[:10]:  # Limit to 10
            context = get_bulletin_context(bulletin_id)
            if context:
                analysis = analyze_with_llm(context)
                results.append({
                    "bulletin_id": bulletin_id,
                    "analysis": analysis
                })
        
        return jsonify({
            "results": results,
            "count": len(results)
        })
    
    except Exception as e:
        logger.error(f"Error in batch analyze: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/recent-errors', methods=['GET'])
def recent_errors():
    """Get recent error bulletins"""
    try:
        minutes = int(request.args.get('minutes', 60))
        
        result = es.search(
            index="nifi-bulletins-*",
            query={
                "bool": {
                    "must": [
                        {"term": {"bulletinLevel": "ERROR"}},
                        {"range": {"@timestamp": {"gte": f"now-{minutes}m"}}}
                    ]
                }
            },
            size=100,
            sort=[{"@timestamp": "desc"}]
        )
        
        bulletins = [hit['_source'] for hit in result['hits']['hits']]
        
        return jsonify({
            "count": len(bulletins),
            "bulletins": bulletins
        })
    
    except Exception as e:
        logger.error(f"Error fetching recent errors: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
