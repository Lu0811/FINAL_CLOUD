output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

# CloudSQL outputs deshabilitados temporalmente
# output "cloudsql_connection_name" {
#   description = "CloudSQL connection name"
#   value       = module.cloudsql.connection_name
# }

# output "cloudsql_private_ip" {
#   description = "CloudSQL private IP"
#   value       = module.cloudsql.private_ip_address
# }

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = module.artifact_registry.repository_url
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}
