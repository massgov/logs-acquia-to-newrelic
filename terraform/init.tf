// Configure the AWS provider.
provider "aws" {
  region = "us-east-1"
  version = "~> 2.70"
}

// Setup remote state storage in an S3 bucket, and inform terraform about
// the bucket that is used so we can reference it from other places.

// Configure the Terraform backend to store state in S3.
terraform {
  backend "s3" {
    bucket               = "application-configurations"
    key                  = "terraform/state/mds-elk.tfstate"
    workspace_key_prefix = "terraform/state/workspaces"
    region               = "us-east-1"
    dynamodb_table       = "terraform"
  }
}

// Allow referencing state based on the current bucket.
locals {
  state_bucket = "application-configurations"
}

