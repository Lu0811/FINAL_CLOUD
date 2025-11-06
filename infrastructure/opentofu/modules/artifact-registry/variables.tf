variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region for the Artifact Registry repository"
  type        = string
}

variable "repository_name" {
  description = "The name of the Artifact Registry repository"
  type        = string
}

variable "description" {
  description = "The description of the repository"
  type        = string
  default     = "Docker repository for AgendaApp images"
}
