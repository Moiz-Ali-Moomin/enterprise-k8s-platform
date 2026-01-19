output "master_ips" {
  description = "IP addresses of K8s master nodes"
  value       = openstack_compute_instance_v2.k8s_master[*].access_ip_v4
}

output "worker_ips" {
  description = "IP addresses of K8s worker nodes"
  value       = openstack_compute_instance_v2.k8s_worker[*].access_ip_v4
}

output "k8s_network_id" {
  description = "ID of the K8s network"
  value       = openstack_networking_network_v2.k8s_net.id
}
