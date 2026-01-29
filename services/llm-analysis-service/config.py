"""
Configuration for NiFi LLM Analysis Service
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Application configuration"""
    
    # Elasticsearch configuration
    ES_CLOUD_ID = os.environ.get('ES_CLOUD_ID')
    ES_API_KEY = os.environ.get('ES_API_KEY')
    ES_URL = os.environ.get('ES_URL')
    
    # LLM Provider (openai, anthropic, azure, custom)
    LLM_PROVIDER = os.environ.get('LLM_PROVIDER', 'openai')
    
    # OpenAI configuration
    OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY')
    OPENAI_MODEL = os.environ.get('OPENAI_MODEL', 'gpt-4-turbo-preview')
    
    # Anthropic configuration
    ANTHROPIC_API_KEY = os.environ.get('ANTHROPIC_API_KEY')
    ANTHROPIC_MODEL = os.environ.get('ANTHROPIC_MODEL', 'claude-3-opus-20240229')
    
    # Azure OpenAI configuration
    AZURE_OPENAI_ENDPOINT = os.environ.get('AZURE_OPENAI_ENDPOINT')
    AZURE_OPENAI_KEY = os.environ.get('AZURE_OPENAI_KEY')
    AZURE_OPENAI_DEPLOYMENT = os.environ.get('AZURE_OPENAI_DEPLOYMENT')
    
    # Custom LLM endpoint
    CUSTOM_LLM_ENDPOINT = os.environ.get('CUSTOM_LLM_ENDPOINT')
    CUSTOM_LLM_API_KEY = os.environ.get('CUSTOM_LLM_API_KEY')
    
    # Model selection based on provider
    @property
    def LLM_MODEL(self):
        if self.LLM_PROVIDER == 'openai':
            return self.OPENAI_MODEL
        elif self.LLM_PROVIDER == 'anthropic':
            return self.ANTHROPIC_MODEL
        elif self.LLM_PROVIDER == 'azure':
            return self.AZURE_OPENAI_DEPLOYMENT
        return 'gpt-4-turbo-preview'
