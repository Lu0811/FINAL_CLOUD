terraform {
  required_version = ">= 1.6"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "./modules/vpc"
  
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  
  subnets = [
    {
      name          = "${var.network_name}-gke-subnet"
      ip_range      = "10.0.0.0/24"
      region        = var.region
      secondary_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.2.0.0/16"
        }
      ]
    }
  ]
}

module "gke" {
  source = "./modules/gke"
  
  project_id       = var.project_id
  region           = var.region
  cluster_name     = var.gke_cluster_name
  network          = module.vpc.network_name
  subnetwork       = module.vpc.subnets_names[0]
  pods_range_name  = "gke-pods"
  services_range_name = "gke-services"
  
  node_pools = [
    {
      name         = "default-pool"
      machine_type = "e2-medium"
      min_count    = 1
      max_count    = 3
      disk_size_gb = 50
    }
  ]
  
  depends_on = [module.vpc]
}

# CloudSQL deshabilitado temporalmente - requiere private service connection
# module "cloudsql" {
#   source = "./modules/cloudsql"
#   
#   project_id        = var.project_id
#   region            = var.region
#   instance_name     = var.cloudsql_instance_name
#   database_version  = "POSTGRES_14"
#   tier              = "db-f1-micro"
#   database_name     = var.database_name
#   network           = module.vpc.network_self_link
#   
#   depends_on = [module.vpc]
# }

module "artifact_registry" {
  source = "./modules/artifact-registry"
  
  project_id      = var.project_id
  region          = var.region
  repository_name = var.artifact_registry_name
  description     = "AgendaApp Docker images"
}
