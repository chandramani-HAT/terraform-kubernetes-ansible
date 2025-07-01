terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "provisioning-prod-tfstate"
    key    = "kube-provisoning-terraform-ansible/terraform.tfstate"
    region = "us-east-1"
  }
}
