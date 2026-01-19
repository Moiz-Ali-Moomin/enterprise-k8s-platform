terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = ">= 1.50.0"
    }
  }
}

provider "openstack" {
  # Credentials sourced from env vars (OS_USERNAME, etc.) or passed via vars
  cloud = var.os_cloud_name
}

# 1. Network Infrastructure
resource "openstack_networking_network_v2" "k8s_net" {
  name           = "k8s-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "k8s_subnet" {
  name       = "k8s-subnet"
  network_id = openstack_networking_network_v2.k8s_net.id
  cidr       = "10.0.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router" {
  name                = "k8s-router"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}

# 2. Security Groups
resource "openstack_networking_secgroup_v2" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for K8s nodes"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.allowed_ssh_cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = var.allowed_api_cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

# 3. Compute Instances (Masters + Workers)
resource "openstack_compute_instance_v2" "k8s_master" {
  count           = 3
  name            = "k8s-master-${count.index}"
  image_name      = "Ubuntu 22.04"
  flavor_name     = "m1.large"
  key_pair        = var.keypair_name
  security_groups = ["default", "${openstack_networking_secgroup_v2.k8s_sg.name}"]

  network {
    uuid = openstack_networking_network_v2.k8s_net.id
  }
}

resource "openstack_compute_instance_v2" "k8s_worker" {
  count           = 5
  name            = "k8s-worker-${count.index}"
  image_name      = "Ubuntu 22.04"
  flavor_name     = "m1.xlarge"
  key_pair        = var.keypair_name
  security_groups = ["default", "${openstack_networking_secgroup_v2.k8s_sg.name}"]

  network {
    uuid = openstack_networking_network_v2.k8s_net.id
  }
  
  # Anti-Affinity Server Group
  scheduler_hints {
    group = openstack_compute_servergroup_v2.k8s_workers_group.id
  }
}

resource "openstack_compute_servergroup_v2" "k8s_workers_group" {
  name     = "k8s-workers-affinity"
  policies = ["anti-affinity"]
}
