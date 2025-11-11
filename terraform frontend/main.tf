# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Locals
locals {
  staging_domain    = "${var.staging_prefix}-${var.domain_name}"
  production_domain = var.domain_name

  domain_names = {
    staging    = local.staging_domain
    production = local.production_domain
  }
}

# DNS and SSL Certificate resources are in separate files:
# - cloudflare.tf (default)
# - route53.tf (alternative)

# S3 Buckets for each environment
resource "aws_s3_bucket" "website" {
  for_each = toset(var.environments)

  bucket = local.domain_names[each.key]

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}"
    Environment = each.key
  })
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  for_each = aws_s3_bucket.website

  bucket = each.value.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 Bucket public access block - Allow public access for static website hosting
resource "aws_s3_bucket_public_access_block" "website" {
  for_each = aws_s3_bucket.website

  bucket = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  for_each = aws_s3_bucket.website

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket website configuration - Removed to match manual deployment pattern
# Manual deployment uses S3 bucket regional domain instead of website endpoint

# CloudFront Origin Access Control - Removed for public S3 access

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  for_each = aws_s3_bucket.website

  origin {
    domain_name         = each.value.bucket_regional_domain_name
    origin_id           = "S3-${each.value.id}"
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "/index.html"
  comment             = "[${upper(each.key)}] ${local.domain_names[each.key]}"

  aliases = [local.domain_names[each.key]]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${each.value.id}"

    # Use AWS managed cache policy (modern approach)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-cloudfront"
    Environment = each.key
  })

  depends_on = [aws_acm_certificate_validation.cloudfront_cert]
}

# S3 Bucket Policy for public read access
resource "aws_s3_bucket_policy" "website" {
  for_each = aws_s3_bucket.website

  bucket = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${each.value.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# DNS records for CloudFront are in separate DNS provider files

# Data source to check if GitHub OIDC provider already exists
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# GitHub OIDC Identity Provider (create only if it doesn't exist)
resource "aws_iam_openid_connect_provider" "github" {
  count = length(data.aws_iam_openid_connect_provider.github.arn) > 0 ? 0 : 1

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-oidc"
  })
}

# Local value to get the OIDC provider ARN (either existing or newly created)
locals {
  github_oidc_provider_arn = length(data.aws_iam_openid_connect_provider.github.arn) > 0 ? data.aws_iam_openid_connect_provider.github.arn : aws_iam_openid_connect_provider.github[0].arn
}

# IAM Role for GitHub Actions deployment
resource "aws_iam_role" "github_actions" {
  for_each = toset(var.environments)

  name = "${var.project_name}-github-actions-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:environment:${each.key}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-github-actions-${each.key}"
    Environment = each.key
  })
}

# IAM Policy for S3 deployment
resource "aws_iam_policy" "s3_deployment" {
  for_each = toset(var.environments)

  name = "${var.project_name}-s3-deployment-${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.website[each.key].arn,
          "${aws_s3_bucket.website[each.key].arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for CloudFront invalidation
resource "aws_iam_policy" "cloudfront_invalidation" {
  for_each = toset(var.environments)

  name = "${var.project_name}-cloudfront-invalidation-${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        Resource = aws_cloudfront_distribution.website[each.key].arn
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "s3_deployment" {
  for_each = toset(var.environments)

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = aws_iam_policy.s3_deployment[each.key].arn
}

resource "aws_iam_role_policy_attachment" "cloudfront_invalidation" {
  for_each = toset(var.environments)

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = aws_iam_policy.cloudfront_invalidation[each.key].arn
}

# Outputs are now in outputs.tf
