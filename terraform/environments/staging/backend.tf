terraform {
  backend "s3" {
    bucket         = "terraform-state-v4vx"
    key            = "dev/tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
