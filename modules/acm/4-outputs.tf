output "acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = try(aws_acm_certificate_validation.this[0].certificate_arn, aws_acm_certificate.this[0].arn)
}

output "acm_certificate_domain_validation_options" {
  description = "A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined."
  value       = aws_acm_certificate.this[0].domain_validation_options
}

output "validation_dns_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name."
  value       = local.use_cloudflare ? [for record in values(cloudflare_dns_record.validation) : record.name] : [for record in values(aws_route53_record.validation) : record.fqdn]
}

output "distinct_domain_names" {
  description = "List of distinct domains names used for the validation."
  value       = local.distinct_domain_names
}

output "validation_domains" {
  description = "List of distinct domain validation options. This is useful if subject alternative names contain wildcards."
  value       = local.validation_domains
}
