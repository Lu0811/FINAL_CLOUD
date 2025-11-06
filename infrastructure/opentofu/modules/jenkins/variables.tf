variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "jenkins_service_account_name" {
  description = "Name for the Jenkins service account"
  type        = string
  default     = "jenkins-sa"
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}
