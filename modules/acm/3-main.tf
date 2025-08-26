# This Terraform configuration creates Cloudflare DNS records for ACM validation.

# [Shared] certificate
resource "aws_acm_certificate" "this" {
  count = var.create_certificate ? 1 : 0

  provider                  = aws.useast1 # Matches CloudFront distribution region
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference ? "ENABLED" : "DISABLED"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

## [Cloudflare] DNS Records for ACM Validation
resource "cloudflare_dns_record" "validation" {
  for_each = local.use_cloudflare && var.create_certificate && var.validate_certificate ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  ttl     = var.dns_ttl
  proxied = var.proxied

  depends_on = [aws_acm_certificate.this]
}

## [Route53] DNS Records for ACM Validation
resource "aws_route53_record" "validation" {
  for_each = local.use_route53 && var.create_certificate && var.validate_certificate ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}

  zone_id = data.aws_route53_zone.this[0].id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60

  depends_on = [aws_acm_certificate.this]
}

## [Shared] ACM cert validation
resource "aws_acm_certificate_validation" "this" {
  count = var.create_certificate && var.validate_certificate && var.wait_for_validation ? 1 : 0

  provider = aws.useast1 # Matches CloudFront distribution region

  certificate_arn = aws_acm_certificate.this[0].arn

  validation_record_fqdns = local.use_cloudflare ? [for record in cloudflare_dns_record.validation : record.name] : [for record in values(aws_route53_record.validation) : record.fqdn]


  # For Cloudflare, we need to wait for DNS propagation
  timeouts {
    create = "30m"
  }

  depends_on = [
    aws_route53_record.validation,
    cloudflare_dns_record.validation
  ]
}
