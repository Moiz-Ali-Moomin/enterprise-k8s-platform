provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  network                    = "default" # Suggest using custom VPC for prod normally
  subnetwork                 = "default"
  
  # Production: Private Cluster
  enable_private_nodes       = true
  enable_private_endpoint    = false 
  master_ipv4_cidr_block     = "172.16.0.0/28"

  ip_range_pods              = "gke-pods"
  ip_range_services          = "gke-services"
  
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
      machine_type              = "e2-standard-4" # Better than e2-medium
      min_count                 = 3
      max_count                 = 10
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 100
      disk_type                 = "pd-ssd" # Production speed
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
