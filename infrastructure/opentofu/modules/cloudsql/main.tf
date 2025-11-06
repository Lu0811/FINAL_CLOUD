resource "google_sql_database_instance" "main" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id
  
  settings {
    tier = var.tier
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network
      require_ssl     = true
    }
    
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      binary_log_enabled = false
    }
    
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
  
  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "google_sql_user" "users" {
  name     = "agendaapp"
  instance = google_sql_database_instance.main.name
  password = var.db_password
  project  = var.project_id
}
