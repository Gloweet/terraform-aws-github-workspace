module "shared-state" {
  source              = "../modules/bootstrap-state"
  region              = "eu-west-3"
  state_bucket_name   = "gloweet-shared-tfstate"
  dynamodb_table_name = "gloweet-shared-tfstate-locks"
  tags = {
    Project   = "shared"
    ManagedBy = "Terraform"
  }
}
