variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "vetrii"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "vetrii-frontend"
}

variable "domain_name" {
  description = "Domain name for the website (e.g., vetrii.com)"
  type        = string
  # This should be set in terraform.tfvars
}

variable "staging_prefix" {
  description = "Prefix for staging environment domain (e.g., 'staging' creates staging-domain.com)"
  type        = string
  default     = "staging"
}

variable "environments" {
  description = "List of environments"
  type        = list(string)
  default     = ["staging", "production"]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "Vetrii Frontend"
    ManagedBy = "Terraform"
    Owner     = "Vetrii"
  }
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone name (e.g., vetrii.com)"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'vetriilabs/vetrii-frontend')"
  type        = string
  default     = ""
}

variable "dns_provider" {
  description = "DNS provider to use (cloudflare or route53)"
  type        = string
  default     = "cloudflare"
  validation {
    condition     = contains(["cloudflare", "route53"], var.dns_provider)
    error_message = "DNS provider must be either 'cloudflare' or 'route53'."
  }
}
