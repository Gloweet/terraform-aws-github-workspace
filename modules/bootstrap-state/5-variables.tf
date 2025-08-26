variable "region" {
  description = "AWS Region"
  type        = string
}

variable "state_bucket_name" {
  description = "State bucket name"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
