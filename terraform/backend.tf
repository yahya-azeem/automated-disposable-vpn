# Remote S3 backend configuration for secure state management and DynamoDB locking.
# Note: Provide your existing bucket and dynamodb_table names before running in production.
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "trusttunnel-vpn/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
