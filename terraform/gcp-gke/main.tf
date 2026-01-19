provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "gke_network" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.vpc_cidr
  region        = var.region
  network       = google_compute_network.gke_network.id

  secondary_ip_range {
    range_name    = var.pod_ip_range_name
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = var.svc_ip_range_name
    ip_cidr_range = "10.2.0.0/16"
  }
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                    = "33.0.0" # Updated to latest stable
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  network                    = google_compute_network.gke_network.name
  subnetwork                 = google_compute_subnetwork.gke_subnet.name
  kubernetes_version         = "1.30"
  
  # Production: Private Cluster
  enable_private_nodes       = true
  enable_private_endpoint    = false 
  master_ipv4_cidr_block     = "172.16.0.0/28"

  ip_range_pods              = var.pod_ip_range_name
  ip_range_services          = var.svc_ip_range_name
  
  # Production: Shielded Nodes & Workload Identity
  enable_shielded_nodes      = true
  identity_namespace         = "${var.project_id}.svc.id.goog"
  
  # Production: Network Policy
  network_policy             = true
  
  # Production: Dataplane V2
  datapath_provider          = "ADVANCED_DATAPATH"

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-standard-4"
      min_count                 = 3
      max_count                 = 10
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 100
      disk_type                 = "pd-ssd"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = true
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
      
      # Production: Secure Boot
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    },
  ]
}

