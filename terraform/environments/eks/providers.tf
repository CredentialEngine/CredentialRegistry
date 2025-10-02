terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

# Configure the AWS provider. Region can also be set via the AWS_REGION env var.
provider "aws" {
  region = "us-east-1"
}
