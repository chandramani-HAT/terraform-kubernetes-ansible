terraform {
  backend "s3" {
    bucket = "provisioning-prod-tfstate"
    key    = "kube-ansi/terraform.tfstate"
    region = "us-east-1"
  }
}
