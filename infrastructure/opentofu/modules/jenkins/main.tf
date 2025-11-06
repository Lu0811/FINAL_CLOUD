resource "google_service_account" "jenkins" {
  account_id   = var.jenkins_service_account_name
  display_name = "Jenkins CI/CD Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "jenkins_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_service_account_iam_member" "jenkins_workload_identity" {
  service_account_id = google_service_account.jenkins.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.jenkins_namespace}/${var.jenkins_service_account_name}]"
}
