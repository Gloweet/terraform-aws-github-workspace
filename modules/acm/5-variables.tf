variable "dns_provider" {
  description = "The DNS provider to use for validation (cloudflare or route53)"
  type        = string
  validation {
    condition     = contains(["cloudflare", "route53"], var.dns_provider)
    error_message = "dns_provider must be either 'cloudflare' or 'route53'"
  }
  nullable = false
}

variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type        = string
  nullable    = false
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "zone_name" {
  description = "The name of the Cloudflare/Route53 zone to contain this record."
  type        = string
  nullable    = false
}

variable "cloudflare_api_token" {
  description = "The Cloudflare API token."
  type        = string
  sensitive   = true
}

variable "create_certificate" {
  description = "Whether to create ACM certificate"
  type        = bool
  default     = true
}

variable "validate_certificate" {
  description = "Whether to validate certificate by creating DNS record"
  type        = bool
  default     = true
}

variable "proxied" {
  description = "Whether to proxy the Cloudflare DNS record"
  type        = bool
  default     = false
}

variable "wait_for_validation" {
  description = "Whether to wait for the validation to complete"
  type        = bool
  default     = true
}

variable "certificate_transparency_logging_preference" {
  description = "Specifies whether certificate details should be added to a certificate transparency log"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "dns_ttl" {
  description = "The TTL of DNS recursive resolvers to cache information about this record."
  type        = number
  # When a DNS record is marked as `proxied` the TTL must be 1 as Cloudflare will control the TTL internally.
  # When a DNS record isn't marked as `proxied`, TTL can be set to 120
  default = 120
}
