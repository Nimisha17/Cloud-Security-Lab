output "vuln_vm_ip" {
  value = google_compute_instance.vuln_vm.network_interface[0].access_config[0].nat_ip
}

output "public_bucket_name" {
  value = google_storage_bucket.public_bucket.name
}

output "function_url" {
  value = google_cloudfunctions_function.unauth_function.https_trigger_url
}
