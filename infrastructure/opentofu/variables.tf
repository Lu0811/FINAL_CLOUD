variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "agendaapp-network"
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "agendaapp-cluster"
}

variable "cloudsql_instance_name" {
  description = "CloudSQL instance name"
  type        = string
  default     = "agendaapp-postgres"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "agendaapp"
}

variable "artifact_registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "agendaapp"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
