#!/usr/bin/env python3
"""
Test LLM Analysis Service
"""
import requests
import json
import sys
import os

SERVICE_URL = os.getenv('LLM_SERVICE_URL', 'http://localhost:5000')

def test_health():
    """Test health endpoint"""
    print("Testing /health endpoint...")
    try:
        response = requests.get(f"{SERVICE_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Health check passed")
            print(f"     Status: {data.get('status')}")
            print(f"     LLM Provider: {data.get('llm_provider')}")
            return True
        else:
            print(f"  ❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"  ⚠️  Service not accessible: {e}")
        return False

def test_analyze_endpoint():
    """Test analyze endpoint with mock data"""
    print("Testing /analyze endpoint...")
    try:
        payload = {
            "bulletin_id": "test-bulletin-id-123"
        }
        response = requests.post(
            f"{SERVICE_URL}/analyze",
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200 or response.status_code == 404:
            # 404 is expected if bulletin doesn't exist
            print(f"  ✅ Analyze endpoint accessible")
            return True
        else:
            print(f"  ❌ Unexpected response: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"  ⚠️  Service not accessible: {e}")
        return False

def test_recent_errors():
    """Test recent-errors endpoint"""
    print("Testing /recent-errors endpoint...")
    try:
        response = requests.get(f"{SERVICE_URL}/recent-errors?minutes=60", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Recent errors endpoint passed")
            print(f"     Found {data.get('count', 0)} bulletins")
            return True
        else:
            print(f"  ❌ Recent errors failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"  ⚠️  Service not accessible: {e}")
        return False

def main():
    """Main test function"""
    print("=" * 50)
    print("LLM Analysis Service Tests")
    print("=" * 50)
    print()
    
    tests = [
        test_health,
        test_analyze_endpoint,
        test_recent_errors
    ]
    
    passed = 0
    failed = 0
    skipped = 0
    
    for test in tests:
        result = test()
        if result is True:
            passed += 1
        elif result is False:
            failed += 1
        else:
            skipped += 1
        print()
    
    print("=" * 50)
    print(f"Results: {passed} passed, {failed} failed, {skipped} skipped")
    print("=" * 50)
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
