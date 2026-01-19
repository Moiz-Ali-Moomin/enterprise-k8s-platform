terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.4.0"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Production Control Plane Nodes
resource "vsphere_virtual_machine" "k8s_master" {
  count            = var.master_count
  name             = "k8s-master-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 4
  memory   = 8192
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 50
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "k8s-master-${count.index + 1}"
        domain    = "internal.corp"
      }
      
      network_interface {
        ipv4_address = cidrhost(var.network_cidr, var.master_ip_start + count.index)
        ipv4_netmask = element(split("/", var.network_cidr), 1)
      }
      
      ipv4_gateway = var.network_gateway
    }
  }
  
  # Anti-Affinity Rule for High Availability
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "masters" {
  name                = "k8s-masters-anti-affinity"
  compute_cluster_id  = data.vsphere_compute_cluster.cluster.id
  virtual_machine_ids = vsphere_virtual_machine.k8s_master[*].id
}

# Production Worker Nodes
resource "vsphere_virtual_machine" "k8s_worker" {
  count            = var.worker_count
  name             = "k8s-worker-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 8
  memory   = 16384
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 100
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "k8s-worker-${count.index + 1}"
        domain    = "internal.corp"
      }
      
      network_interface {
        ipv4_address = cidrhost(var.network_cidr, var.worker_ip_start + count.index)
        ipv4_netmask = element(split("/", var.network_cidr), 1)
      }
      
      ipv4_gateway = var.network_gateway
    }
  }
}
