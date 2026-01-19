terraform {
  backend "gcs" {
    bucket = "enterprise-k8s-platform-tfstate"
    prefix = "gcp-gke"
  }
}
