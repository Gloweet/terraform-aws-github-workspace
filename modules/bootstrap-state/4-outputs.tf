output "terraform_state_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_bucket_region" {
  description = "The AWS region of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "terraform_state_bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket (if website hosting enabled)"
  value       = aws_s3_bucket.terraform_state.website_endpoint
}

output "terraform_state_bucket_tags" {
  description = "Tags of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.tags
}

output "terraform_state_bucket_versioning" {
  description = "Versioning configuration of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.versioning
}

output "terraform_state_bucket_server_side_encryption" {
  description = "Server-side encryption configuration of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.server_side_encryption_configuration
}


output "dynamodb_table" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}
