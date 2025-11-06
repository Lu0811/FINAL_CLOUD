resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
  
  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.network
  subnetwork = var.subnetwork
  
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
  
  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "pools" {
  count = length(var.node_pools)
  
  name       = var.node_pools[count.index].name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  
  initial_node_count = var.node_pools[count.index].min_count
  
  autoscaling {
    min_node_count = var.node_pools[count.index].min_count
    max_node_count = var.node_pools[count.index].max_count
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  node_config {
    machine_type = var.node_pools[count.index].machine_type
    disk_size_gb = var.node_pools[count.index].disk_size_gb
    disk_type    = "pd-standard"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    labels = {
      environment = var.environment
      cluster     = var.cluster_name
    }
    
    tags = ["gke-node", "${var.cluster_name}-node"]
  }
}
