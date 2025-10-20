terraform {
  backend "s3" {
    bucket         = "terraform-state-o1r8"
    key            = "eks-registry/tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
