#!/usr/bin/env python3
"""
Dynamic Ansible Inventory Generator
Returns JSON inventory that works with ansible-inventory --list
"""

import json
import yaml
import argparse
from pathlib import Path
import sys

def load_yaml_files(directory="."):
    """Load all YAML files from the specified directory"""
    yaml_files = []
    yaml_extensions = ['.yml', '.yaml']
    
    for file_path in Path(directory).glob("**/*"):
        if file_path.is_file() and file_path.suffix.lower() in yaml_extensions:
            try:
                with open(file_path, 'r') as f:
                    content = yaml.safe_load(f)
                    if content:
                        yaml_files.append({
                            'path': str(file_path),
                            'content': content
                        })
            except Exception as e:
                # Send errors to stderr so they don't interfere with JSON output
                print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
    
    return yaml_files

def extract_inventory_data(yaml_files):
    """Extract inventory data from YAML files"""
    groups = {}
    all_hosts = {}
    
    for yaml_file in yaml_files:
        content = yaml_file['content']
        
        if isinstance(content, dict):
            for key, value in content.items():
                # Skip non-inventory keys
                if key in ['name', 'tasks', 'handlers', 'vars_files', 'become', 'gather_facts']:
                    continue
                
                # Handle group definitions
                if isinstance(value, dict) and 'hosts' in value:
                    group_name = key
                    groups[group_name] = {
                        'hosts': [],
                        'vars': value.get('vars', {}),
                        'children': value.get('children', [])
                    }
                    
                    for host, host_vars in value['hosts'].items():
                        groups[group_name]['hosts'].append(host)
                        all_hosts[host] = host_vars or {}
                
                # Handle simple host lists
                elif isinstance(value, list):
                    group_name = key
                    groups[group_name] = {'hosts': [], 'vars': {}, 'children': []}
                    
                    for item in value:
                        if isinstance(item, str):
                            groups[group_name]['hosts'].append(item)
                            all_hosts[item] = {}
                        elif isinstance(item, dict):
                            for hostname, host_vars in item.items():
                                groups[group_name]['hosts'].append(hostname)
                                all_hosts[hostname] = host_vars or {}
    
    return groups, all_hosts

def generate_dynamic_inventory(groups, all_hosts):
    """Generate dynamic inventory JSON"""
    inventory = {}
    
    # Add groups
    for group_name, group_data in groups.items():
        inventory[group_name] = {
            'hosts': group_data['hosts']
        }
        
        if group_data['vars']:
            inventory[group_name]['vars'] = group_data['vars']
        
        if group_data['children']:
            inventory[group_name]['children'] = group_data['children']
    
    # Add _meta section with host variables
    inventory['_meta'] = {
        'hostvars': all_hosts
    }
    
    return inventory

def main():
    parser = argparse.ArgumentParser(description='Dynamic Ansible inventory from YAML files')
    parser.add_argument('--list', action='store_true', default=True,
                       help='List all hosts (default)')
    parser.add_argument('--host', 
                       help='Get variables for a specific host')
    parser.add_argument('--directory', '-d', default='.', 
                       help='Directory to scan for YAML files')
    
    args = parser.parse_args()
    
    yaml_files = load_yaml_files(args.directory)
    
    if not yaml_files:
        print("{}", file=sys.stderr)
        sys.exit(1)
    
    groups, all_hosts = extract_inventory_data(yaml_files)
    
    if args.host:
        # Return specific host variables
        host_vars = all_hosts.get(args.host, {})
        print(json.dumps(host_vars, indent=2))
    else:
        # Return full inventory
        inventory = generate_dynamic_inventory(groups, all_hosts)
        print(json.dumps(inventory, indent=2))

if __name__ == "__main__":
    main()