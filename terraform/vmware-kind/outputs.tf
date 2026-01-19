output "master_ips" {
  description = "IP addresses of master nodes"
  value       = vsphere_virtual_machine.k8s_master[*].default_ip_address
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = vsphere_virtual_machine.k8s_worker[*].default_ip_address
}

output "vcenter_server" {
  description = "vCenter server address"
  value       = var.vsphere_server
}
