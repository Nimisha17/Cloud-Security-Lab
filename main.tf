provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# -----------------------
# IAM Misconfigs
# -----------------------

# Service Account with too much privilege
resource "google_service_account" "ci_cd" {
  account_id   = "sa-ci-cd"
  display_name = "CI/CD Service Account"
}

# Bind Owner role at project level
resource "google_project_iam_member" "sa_owner_binding" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.ci_cd.email}"
}

# Low-privileged developer user with SA impersonation ability
resource "google_project_iam_member" "dev_sauser" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "user:developer1@example.com" # <-- replace with your test user
}

# Dormant old admin
resource "google_project_iam_member" "old_admin" {
  project = var.project_id
  role    = "roles/editor"
  member  = "user:old-admin@example.com" # intentionally left
}

# -----------------------
# Storage Misconfigs
# -----------------------

# Public bucket with sensitive file
resource "google_storage_bucket" "public_bucket" {
  name          = "${var.project_id}-public-data-vuln"
  location      = var.region
  force_destroy = true
}

# Make it world-readable
resource "google_storage_bucket_iam_member" "allusers_viewer" {
  bucket = google_storage_bucket.public_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload fake creds file
resource "google_storage_bucket_object" "fake_creds" {
  name   = "credentials.txt"
  bucket = google_storage_bucket.public_bucket.name
  content = <<EOT
  FLAG{bucket_exposed_creds}
  EOT
}

# -----------------------
# Compute + Networking
# -----------------------

# VPC firewall rule: open SSH to world
resource "google_compute_firewall" "allow_ssh_world" {
  name    = "allow-ssh-world"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# VM with default service account (Editor role by default!)
resource "google_compute_instance" "vuln_vm" {
  name         = "vuln-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network       = "default"
    access_config {} # assigns external IP
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    echo "FLAG{vm_metadata_api}" > /tmp/flag.txt
    # weak web app with SSRF simulation
    python3 -m http.server 8080 &
  EOT
}

# -----------------------
# Cloud Function (Unauth)
# -----------------------

resource "google_storage_bucket" "cf_bucket" {
  name          = "${var.project_id}-cf-source"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "cf_zip" {
  name   = "function.zip"
  bucket = google_storage_bucket.cf_bucket.name
  source = "function.zip" # <-- zip of index.js or main.py
}

resource "google_cloudfunctions2_function" "unauth_function" {
  name     = "leaky-func"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "hello_http"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_bucket.name
        object = google_storage_bucket_object.cf_zip.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "128M"
    ingress_settings   = "ALLOW_ALL"

    environment_variables = {
      SECRET_FLAG = "FLAG{cloud_function_leak}"
    }
  }
}


# Allow allUsers invocation
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.unauth_function.project
  region         = google_cloudfunctions_function.unauth_function.region
  cloud_function = google_cloudfunctions_function.unauth_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
