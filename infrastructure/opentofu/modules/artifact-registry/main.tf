resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repository_name
  description   = var.description
  format        = "DOCKER"
  project       = var.project_id
}
