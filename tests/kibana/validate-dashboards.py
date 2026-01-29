#!/usr/bin/env python3
"""
Validate Kibana dashboards
"""
import json
import os
import sys

def validate_dashboard(filepath):
    """Validate a single dashboard file"""
    print(f"Validating {os.path.basename(filepath)}...")
    
    try:
        with open(filepath, 'r') as f:
            dashboard = json.load(f)
        
        # Check required fields
        required_fields = ['id', 'type', 'attributes']
        for field in required_fields:
            if field not in dashboard:
                print(f"  ❌ Missing required field: {field}")
                return False
        
        # Check type
        if dashboard['type'] != 'dashboard':
            print(f"  ❌ Invalid type: {dashboard['type']}")
            return False
        
        # Check attributes
        attrs = dashboard['attributes']
        if 'title' not in attrs or 'panelsJSON' not in attrs:
            print(f"  ❌ Missing required attributes")
            return False
        
        print(f"  ✅ Valid dashboard: {attrs['title']}")
        return True
    
    except json.JSONDecodeError as e:
        print(f"  ❌ JSON parse error: {e}")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def main():
    """Main test function"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    dashboards_dir = os.path.join(project_root, 'kibana', 'dashboards')
    
    if not os.path.exists(dashboards_dir):
        print(f"❌ Dashboards directory not found: {dashboards_dir}")
        return 1
    
    dashboard_files = [f for f in os.listdir(dashboards_dir) if f.endswith('.ndjson')]
    
    if not dashboard_files:
        print("❌ No dashboard files found")
        return 1
    
    print(f"Found {len(dashboard_files)} dashboard(s)")
    print()
    
    passed = 0
    failed = 0
    
    for filename in sorted(dashboard_files):
        filepath = os.path.join(dashboards_dir, filename)
        if validate_dashboard(filepath):
            passed += 1
        else:
            failed += 1
    
    print()
    print(f"Results: {passed} passed, {failed} failed")
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
