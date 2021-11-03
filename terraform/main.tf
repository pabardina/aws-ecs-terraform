terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "override-me" # will be override in the terraform cli
    key    = "terraform.tfsate"
    region = "ca-central-1"
  }
}

provider "aws" {
  region = "ca-central-1"
  default_tags {
   tags = {
     Owner       = "devops"
     Project     = "flask-app"
     Managed_by  = "terraform"
   }
 }
}