#!/usr/bin/env python3
"""
Validate Kibana dashboards exist and are properly configured
"""

import os
import json
import sys

def validate_dashboard_file(filepath):
    """Validate a single dashboard file"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Parse NDJSON
        lines = content.strip().split('\n')
        for line in lines:
            if line:
                obj = json.loads(line)
                
                # Check for required fields
                if 'attributes' in obj:
                    attrs = obj['attributes']
                    if 'title' not in attrs:
                        print(f"✗ {filepath}: Missing title")
                        return False
                    
                    if not attrs['title'].startswith('[NiFi]'):
                        print(f"⚠ {filepath}: Title doesn't start with [NiFi]")
        
        return True
    except Exception as e:
        print(f"✗ {filepath}: Error - {e}")
        return False

def main():
    print("========================================")
    print("Validating Kibana Dashboards")
    print("========================================\n")
    
    # Find the repository root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, '..', '..'))
    dashboard_dir = os.path.join(repo_root, "kibana", "dashboards")
    
    if not os.path.exists(dashboard_dir):
        print(f"✗ Dashboard directory not found: {dashboard_dir}")
        return 1
    
    dashboard_files = [f for f in os.listdir(dashboard_dir) if f.endswith('.ndjson')]
    
    if len(dashboard_files) < 7:
        print(f"⚠ Expected 7 dashboards, found {len(dashboard_files)}")
    
    passed = 0
    failed = 0
    
    for dashboard_file in dashboard_files:
        filepath = os.path.join(dashboard_dir, dashboard_file)
        if validate_dashboard_file(filepath):
            print(f"✅ {dashboard_file}")
            passed += 1
        else:
            failed += 1
    
    print(f"\n========================================")
    print(f"Results: {passed} passed, {failed} failed")
    print(f"========================================")
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
