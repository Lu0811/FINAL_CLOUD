output "jenkins_service_account_email" {
  description = "Email of the Jenkins service account"
  value       = google_service_account.jenkins.email
}

output "jenkins_service_account_name" {
  description = "Name of the Jenkins service account"
  value       = google_service_account.jenkins.name
}
