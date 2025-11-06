output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "subnets_names" {
  description = "Subnet names"
  value       = google_compute_subnetwork.subnets[*].name
}

output "subnets_self_links" {
  description = "Subnet self links"
  value       = google_compute_subnetwork.subnets[*].self_link
}
