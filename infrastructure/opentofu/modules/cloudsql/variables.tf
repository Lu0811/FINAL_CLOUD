variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "instance_name" {
  description = "CloudSQL instance name"
  type        = string
}

variable "database_version" {
  description = "Database version"
  type        = string
  default     = "POSTGRES_14"
}

variable "tier" {
  description = "Machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "network" {
  description = "VPC network self link"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"
  sensitive   = true
}
