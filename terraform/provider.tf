terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # The backend block MUST be inside the terraform block
  # Replace YOUR_BACKEND_BUCKET_NAME with your actual S3 backend bucket name
  backend "s3" {
    bucket = "s3-cicd-tf-saby" # Replace with your backend bucket name
    key    = "cloudfront-site/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  # Default tags that will be applied to all resources created by this provider
  default_tags {
    tags = {
      Environment = "Dev"
      Project     = "Terraform-Learning"
      Owner       = "Gaurav"
    }
  }
}