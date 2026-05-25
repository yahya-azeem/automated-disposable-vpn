# Remote S3 backend configuration for secure state management and DynamoDB locking.
# Note: Commented out for local testing with Floci. Using local state.
/*
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "trusttunnel-vpn/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
*/
