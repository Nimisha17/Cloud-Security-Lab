# Cloud-Security-Lab
Home lab to learn cloud(GCP) based security vulnerabilities. This is a project in progress that gets updated with new vulnerabilities starting with misconfigurations.


Deploying the terraform sets up a vulnerable environment with around 4 vulnerabilities. 

The following 4 vulnerabilities are highlihted in this lab.
1. **IAM Privilege Escalation**  
   - A service account (`sa-ci-cd`) is granted `roles/owner`.  
   - A low-privileged user can impersonate it and escalate to project owner.

2. **Public Cloud Storage Bucket**  
   - A bucket is world-readable (`allUsers: objectViewer`).  
   - Contains fake sensitive data + a flag (`FLAG{bucket_exposed_creds}`).

3. **Insecure Compute VM**  
   - A VM has SSH open to `0.0.0.0/0`.  
   - It runs with the default service account (Editor role).  
   - Flag stored in `/tmp/flag.txt`.

4. **Unauthenticated Cloud Function**  
   - A Cloud Function (2nd Gen) is deployed with `roles/run.invoker` for `allUsers`.  
   - It leaks an environment variable secret (`FLAG{cloud_function_leak}`).

---

## Deployment Instructions

### Prerequisites
- A GCP project (use free-tier / new sandbox project).  
- [gcloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated:  
  ```bash
  gcloud auth application-default login
  gcloud config set project <YOUR_PROJECT_ID>


Note: Replace the email ids in the config file before deploying.
further clear instructions on adding missing resources will be updated.

## Clean-up:
- delete the instances using terraform to clean up.
  ```bash
  terraform destroy -var="project_id=<YOUR_PROJECT_ID>"
