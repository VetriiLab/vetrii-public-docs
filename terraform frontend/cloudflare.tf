# Cloudflare DNS Provider Configuration
# This file contains Cloudflare-specific DNS resources
# To use Route53 instead, rename this file to cloudflare.tf.disabled and route53.tf.disabled to route53.tf

# Get the Cloudflare zone for the domain
data "cloudflare_zone" "main" {
  name = var.cloudflare_zone_name
}

# ACM Certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  provider          = aws.us_east_1

  subject_alternative_names = [
    "*.${var.domain_name}",
    local.staging_domain
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-cloudfront-cert"
    Environment = "shared"
  })
}

# Certificate validation records in Cloudflare
resource "cloudflare_record" "cert_validation" {
  for_each = {
    # Note: we need to deduplicate the records because ACM uses the same record for multiple domains
    for dvo in distinct([
      for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options :
      {
        name  = dvo.resource_record_name
        type  = dvo.resource_record_type
        value = dvo.resource_record_value
      }
    ]) : dvo.name => dvo
  }

  zone_id = data.cloudflare_zone.main.id
  name    = each.value.name
  content = each.value.value
  type    = each.value.type
  ttl     = 60
  # If records already exist, allow overwriting them
  allow_overwrite = true
  comment         = "CF certificate validation for ${var.project_name}. By Terraform"
}

resource "aws_acm_certificate_validation" "cloudfront_cert" {
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
  provider                = aws.us_east_1

  timeouts {
    create = "5m"
  }
}

# Cloudflare DNS records for CloudFront
resource "cloudflare_record" "website" {
  for_each = aws_cloudfront_distribution.website

  zone_id = data.cloudflare_zone.main.id
  name    = local.domain_names[each.key]
  # name    = local.domain_names[each.key] == var.domain_name ? "@" : local.domain_names[each.key]
  content = each.value.domain_name
  type    = "CNAME"
  ttl     = 1     # Auto TTL
  proxied = false # Don't proxy through Cloudflare, let CloudFront handle it

  comment = "CF distribution for ${var.project_name} ${each.value.tags.Environment}. By Terraform"
  # If records already exist, allow overwriting them
  allow_overwrite = true
}



# Cloudflare-specific outputs
output "cloudflare_zone_id" {
  description = "The Cloudflare zone ID"
  value       = data.cloudflare_zone.main.id
}

output "cloudflare_zone_name" {
  description = "The Cloudflare zone name"
  value       = data.cloudflare_zone.main.name
}
