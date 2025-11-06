output "connection_name" {
  description = "CloudSQL connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

output "instance_name" {
  description = "Instance name"
  value       = google_sql_database_instance.main.name
}
