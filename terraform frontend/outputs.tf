# DNS Provider Outputs
# Note: Only outputs for the active DNS provider will be available
# Check the provider .tf files to see which provider is active and its outputs

output "s3_bucket_names" {
  description = "S3 bucket names for each environment"
  value = {
    for env in var.environments : env => aws_s3_bucket.website[env].bucket
  }
}

output "cloudfront_distribution_ids" {
  description = "CloudFront distribution IDs for each environment"
  value = {
    for env in var.environments : env => aws_cloudfront_distribution.website[env].id
  }
}

output "website_urls" {
  description = "Website URLs for each environment"
  value = {
    for env in var.environments : env => "https://${local.domain_names[env]}"
  }
}

output "cloudfront_domains" {
  description = "CloudFront domain names for each environment"
  value = {
    for env in var.environments : env => aws_cloudfront_distribution.website[env].domain_name
  }
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.cloudfront_cert.arn
}

output "iam_role_arns" {
  description = "IAM role ARNs for GitHub Actions"
  value = {
    for env in var.environments : env => aws_iam_role.github_actions[env].arn
  }
}

output "s3_bucket_regional_domains" {
  description = "S3 bucket regional domain names for each environment"
  value = {
    for env in var.environments : env => aws_s3_bucket.website[env].bucket_regional_domain_name
  }
}

output "domain_configuration" {
  description = "Domain configuration for each environment"
  value = {
    for env in var.environments : env => {
      domain             = local.domain_names[env]
      s3_bucket          = aws_s3_bucket.website[env].bucket
      s3_regional_domain = aws_s3_bucket.website[env].bucket_regional_domain_name
      cloudfront_id      = aws_cloudfront_distribution.website[env].id
      cloudfront_url     = aws_cloudfront_distribution.website[env].domain_name
      custom_domain_url  = "https://${local.domain_names[env]}"
    }
  }
}
