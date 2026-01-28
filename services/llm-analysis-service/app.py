from flask import Flask, request, jsonify
from datetime import datetime
import os
import json
from elasticsearch import Elasticsearch
import openai
import anthropic

app = Flask(__name__)

# Configuration
ES_CLOUD_ID = os.getenv('ES_CLOUD_ID')
ES_API_KEY = os.getenv('ES_API_KEY')
LLM_PROVIDER = os.getenv('LLM_PROVIDER', 'openai')
LLM_API_KEY = os.getenv('LLM_API_KEY')
LLM_MODEL = os.getenv('LLM_MODEL', 'gpt-4-turbo')

# Initialize Elasticsearch client
es_client = Elasticsearch(
    cloud_id=ES_CLOUD_ID,
    api_key=ES_API_KEY
) if ES_CLOUD_ID and ES_API_KEY else None

# Initialize LLM clients
if LLM_PROVIDER == 'openai':
    openai.api_key = LLM_API_KEY
elif LLM_PROVIDER == 'anthropic':
    anthropic_client = anthropic.Anthropic(api_key=LLM_API_KEY)


def get_bulletin_context(bulletin_id):
    """Fetch bulletin and related context from Elasticsearch"""
    if not es_client:
        return None
    
    try:
        # Get the specific bulletin
        response = es_client.search(
            index='nifi-bulletins-*',
            body={
                'query': {
                    'term': {
                        'bulletinId': bulletin_id
                    }
                }
            }
        )
        
        if not response['hits']['hits']:
            return None
        
        bulletin = response['hits']['hits'][0]['_source']
        
        # Get recent related bulletins (same component, last 1 hour)
        related_response = es_client.search(
            index='nifi-bulletins-*',
            body={
                'query': {
                    'bool': {
                        'must': [
                            {'term': {'bulletinSourceName': bulletin.get('bulletinSourceName')}},
                            {'range': {'@timestamp': {'gte': 'now-1h'}}}
                        ]
                    }
                },
                'size': 10,
                'sort': [{'@timestamp': 'desc'}]
            }
        )
        
        related_bulletins = [hit['_source'] for hit in related_response['hits']['hits']]
        
        # Get system diagnostics around the same time
        system_response = es_client.search(
            index='nifi-system-diagnostics-*',
            body={
                'query': {
                    'range': {
                        '@timestamp': {
                            'gte': bulletin.get('@timestamp'),
                            'lte': 'now'
                        }
                    }
                },
                'size': 5,
                'sort': [{'@timestamp': 'desc'}]
            }
        )
        
        system_metrics = [hit['_source'] for hit in system_response['hits']['hits']]
        
        return {
            'bulletin': bulletin,
            'related_bulletins': related_bulletins,
            'system_metrics': system_metrics
        }
    except Exception as e:
        print(f"Error fetching context: {e}")
        return None


def analyze_with_llm(context):
    """Analyze the bulletin context using LLM"""
    
    # Prepare the prompt
    prompt = f"""You are an expert Apache NiFi troubleshooting assistant. Analyze the following NiFi bulletin and provide:
1. Root cause analysis
2. Immediate action items
3. Prevention recommendations
4. Impact assessment (High/Medium/Low)

Bulletin Details:
- Level: {context['bulletin'].get('bulletinLevel')}
- Message: {context['bulletin'].get('bulletinMessage')}
- Source: {context['bulletin'].get('bulletinSourceName')} ({context['bulletin'].get('bulletinSourceType')})
- Category: {context['bulletin'].get('bulletinCategory')}
- Timestamp: {context['bulletin'].get('@timestamp')}

Related Recent Bulletins (last hour):
{json.dumps([b.get('bulletinMessage') for b in context['related_bulletins'][:3]], indent=2)}

Recent System Metrics:
- Heap Utilization: {context['system_metrics'][0].get('heapUtilization', 'N/A')}%
- Total Threads: {context['system_metrics'][0].get('totalThreads', 'N/A')}
- Processor Load: {context['system_metrics'][0].get('processorLoadAverage', 'N/A')}

Provide a structured analysis in JSON format with keys: root_cause, immediate_actions (array), prevention (array), impact, confidence (0-1).
"""
    
    try:
        if LLM_PROVIDER == 'openai':
            response = openai.ChatCompletion.create(
                model=LLM_MODEL,
                messages=[
                    {"role": "system", "content": "You are an expert Apache NiFi troubleshooting assistant. Respond with valid JSON only."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3
            )
            analysis_text = response.choices[0].message.content
            
        elif LLM_PROVIDER == 'anthropic':
            message = anthropic_client.messages.create(
                model=LLM_MODEL,
                max_tokens=1024,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            analysis_text = message.content[0].text
        else:
            return {
                'error': 'Unsupported LLM provider'
            }
        
        # Parse JSON response
        analysis = json.loads(analysis_text)
        return analysis
        
    except json.JSONDecodeError:
        # If LLM didn't return valid JSON, create a structured response
        return {
            'root_cause': analysis_text[:200],
            'immediate_actions': ['Review the error message and logs'],
            'prevention': ['Monitor system metrics'],
            'impact': 'Medium',
            'confidence': 0.5
        }
    except Exception as e:
        print(f"Error in LLM analysis: {e}")
        return {
            'error': str(e)
        }


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'elasticsearch': 'connected' if es_client else 'not configured',
        'llm_provider': LLM_PROVIDER
    })


@app.route('/analyze', methods=['POST'])
def analyze():
    """Analyze a bulletin and provide recommendations"""
    data = request.get_json()
    
    if not data or 'bulletin_id' not in data:
        return jsonify({'error': 'bulletin_id is required'}), 400
    
    bulletin_id = data['bulletin_id']
    
    # Get context
    context = get_bulletin_context(bulletin_id)
    if not context:
        return jsonify({'error': 'Bulletin not found or Elasticsearch not configured'}), 404
    
    # Analyze with LLM
    analysis = analyze_with_llm(context)
    
    # Return response
    return jsonify({
        'bulletin_id': bulletin_id,
        'analysis': analysis,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    })


@app.route('/batch-analyze', methods=['POST'])
def batch_analyze():
    """Analyze multiple bulletins"""
    data = request.get_json()
    
    if not data or 'bulletin_ids' not in data:
        return jsonify({'error': 'bulletin_ids array is required'}), 400
    
    results = []
    for bulletin_id in data['bulletin_ids']:
        context = get_bulletin_context(bulletin_id)
        if context:
            analysis = analyze_with_llm(context)
            results.append({
                'bulletin_id': bulletin_id,
                'analysis': analysis
            })
    
    return jsonify({
        'results': results,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    })


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
