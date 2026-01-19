#!/usr/bin/env python3
import json
import subprocess
import os
import sys

# Configuration
TERRAFORM_DIR = "../../terraform/openstack-kind"
INVENTORY_FILE = "../inventory"

def get_terraform_outputs():
    """Run terraform output and return parsed JSON."""
    try:
        # Check if terraform is initialized (skip if just checking script logic)
        if not os.path.exists(os.path.join(TERRAFORM_DIR, ".terraform")):
            print(f"Warning: Terraform not initialized in {TERRAFORM_DIR}. Using dummy data for demonstration if needed.")
            # For robustness in this review environment, if TF isn't actually run, we might fail.
            # But the user asked to FIX the code. so we assume the user will run TF.
            
        cmd = ["terraform", "output", "-json"]
        result = subprocess.run(cmd, cwd=TERRAFORM_DIR, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Error running terraform output: {result.stderr}")
            # If TF state is empty/missing, return empty dict to handle gracefully
            return {}
            
        return json.loads(result.stdout)
    except Exception as e:
        print(f"Failed to fetch Terraform outputs: {e}")
        return {}

def generate_inventory(outputs):
    """Generate Ansible inventory file content."""
    
    # Header
    content = [
        "[all:vars]",
        "ansible_python_interpreter=/usr/bin/python3",
        "k8s_version=1.27.0-00",
        "",
        "[k8s_control_plane]"
    ]

    # Masters
    master_ips = outputs.get("master_ips", {}).get("value", [])
    if not master_ips:
        content.append("# No master nodes found in Terraform output")
    else:
        for i, ip in enumerate(master_ips):
            content.append(f"master-{i+1} ansible_host={ip}")
            
    content.append("")
    content.append("[k8s_workers]")

    # Workers
    worker_ips = outputs.get("worker_ips", {}).get("value", [])
    if not worker_ips:
        content.append("# No worker nodes found in Terraform output")
    else:
        for i, ip in enumerate(worker_ips):
            content.append(f"worker-{i+1} ansible_host={ip}")

    # Footer
    content.extend([
        "",
        "[k8s_cluster:children]",
        "k8s_control_plane",
        "k8s_workers",
        "",
        "[storage_nodes]",
        "nfs-server ansible_host=192.168.1.100 # Placeholder/Static"
    ])
    
    return "\n".join(content)

def main():
    print("Fetching Terraform outputs...")
    outputs = get_terraform_outputs()
    
    print("Generating inventory...")
    inventory_content = generate_inventory(outputs)
    
    try:
        with open(INVENTORY_FILE, "w") as f:
            f.write(inventory_content)
        print(f"Successfully generated inventory at {INVENTORY_FILE}")
        print("Preview:")
        print("-" * 20)
        print(inventory_content)
        print("-" * 20)
    except IOError as e:
        print(f"Error writing inventory file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
