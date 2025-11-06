variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "subnets" {
  description = "List of subnets"
  type = list(object({
    name          = string
    ip_range      = string
    region        = string
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
}
