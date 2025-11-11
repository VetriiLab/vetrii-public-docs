# React Frontend Infrastructure

Deploy a React frontend with S3 hosting, CloudFront CDN, and SSL certificates using Terraform. Supports both Cloudflare and Route53 DNS providers.

## Quick Start

### 1. Prerequisites
- AWS account with appropriate permissions
- Domain name registered
- Terraform >= 1.12 installed
- AWS CLI configured
- For Cloudflare: Domain added to Cloudflare + API token
- For Route53: Access to domain registrar settings
- We recommend using AWS profiles for better security and isolation. If using it, you must prepend the environment variable `AWS_PROFILE` to the terraform commands.

### 2. Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your required values
```

### 3. Initialize & Deploy

**Using AWS Profile (recommended)**
```bash
AWS_PROFILE=your-profile-name terraform init
AWS_PROFILE=your-profile-name terraform plan
AWS_PROFILE=your-profile-name terraform apply
# don't forget to do the same for all terraform commands!
```

**Using Default AWS Credentials (not recommended)**
```bash
terraform init
terraform plan
terraform apply
```

### 4. Update DNS
- **Cloudflare**: Records created automatically
- **Route53**: Update registrar with provided name servers

That's it! Your site will be available at `https://vetrii.com`

## What You Get

- **S3 Buckets**: Static hosting for staging and production
- **CloudFront**: Global CDN with SSL termination
- **SSL Certificates**: Auto-renewed ACM certificates
- **DNS Records**: Automatic DNS configuration
- **IAM Roles**: GitHub Actions deployment permissions

**Domain Structure:**
- Production: `vetrii.com`
- Staging: `staging-vetrii.com` (prepend format, not subdomain)


## DNS Provider Options

### Cloudflare (Default)
- ✅ Free DNS hosting
- ✅ Advanced features
- ✅ No AWS DNS costs
- ❌ Requires existing Cloudflare zone

### Route53 (Alternative)
- ✅ Full AWS integration
- ✅ Advanced routing options
- ✅ Creates hosted zone automatically
- ❌ ~$0.50/month + query charges

## Switching DNS Providers

### To Route53
```bash
mv cloudflare.tf cloudflare.tf.disabled
mv route53.tf.disabled route53.tf
# Update terraform.tfvars: dns_provider = "route53"

terraform plan && terraform apply
```

### To Cloudflare
```bash
mv route53.tf route53.tf.disabled
mv cloudflare.tf.disabled cloudflare.tf
# Update terraform.tfvars: dns_provider = "cloudflare"

terraform plan && terraform apply
```

## Deployment Integration

### GitHub Actions
The infrastructure creates IAM roles for GitHub Actions deployment:

Get values from terraform outputs:
```bash
terraform output s3_bucket_names
terraform output cloudfront_distribution_ids

# DNS provider specific outputs
terraform output cloudflare_zone_id      # if using Cloudflare
terraform output route53_name_servers    # if using Route53
```

## Troubleshooting

### Common Issues

**AWS CLI Permissions Issue**
- Check AWS CLI permissions
- Verify AWS CLI is configured correctly
- If using AWS profile, check if you have prepended `AWS_PROFILE=your-profile-name` to the command

**SSL Certificate Pending**
- Check DNS propagation
- Verify DNS records were created

**CloudFront 403 Errors**
- Check S3 bucket policy
- Verify public access settings

**DNS Not Resolving**
- Cloudflare: Ensure records aren't proxied (orange cloud off)
- Route53: Update registrar name servers

**Provider Switching Issues**
- Ensure only one DNS provider file is active (`.tf` extension)
- Run `terraform plan` to verify changes

### Debug Commands
```bash
# Check Terraform resources
terraform state list
terraform output

# Check AWS resources
aws s3 ls --profile your-profile
aws cloudfront list-distributions --profile your-profile

# DNS specific
aws route53 list-hosted-zones --profile your-profile  # Route53
curl -H "Authorization: Bearer TOKEN" https://api.cloudflare.com/client/v4/zones  # Cloudflare
```

## File Structure

```
terraform/
├── main.tf                    # Core infrastructure
├── provider.tf               # Provider configurations
├── variables.tf              # Variable definitions
├── outputs.tf                # Output definitions
├── backend.tf                # Terraform backend
├── cloudflare.tf             # Cloudflare DNS (default)
├── route53.tf.disabled       # Route53 DNS (alternative)
├── terraform.tfvars.example  # Example configuration
└── terraform.tfvars          # Your configuration
```

## Architecture Details

### S3 Configuration
- **Public access**: Enabled for static hosting
- **Bucket policy**: Public read access
- **Versioning**: Disabled (matches manual deployment pattern)
- **Encryption**: AES256 server-side encryption

### CloudFront Configuration
- **Origin**: S3 bucket regional domain (not website endpoint)
- **Cache policy**: AWS managed CachingOptimized policy
- **SSL**: ACM certificate with SNI
- **Error handling**: SPA routing (404/403 → index.html)
- **Compression**: Enabled
- **Price class**: Global (PriceClass_All)

### DNS Configuration

#### Cloudflare
- **Zone**: Uses existing Cloudflare zone
- **Records**: CNAME records to CloudFront
- **SSL validation**: DNS records in Cloudflare
- **Proxying**: Disabled (direct to CloudFront)

#### Route53
- **Zone**: Creates new hosted zone
- **Records**: A records with CloudFront aliases
- **SSL validation**: DNS records in Route53
- **Integration**: Full AWS integration

### Security
- **S3**: Public read-only access
- **CloudFront**: HTTPS redirect enforced
- **SSL**: TLS 1.2+ minimum
- **IAM**: Least privilege GitHub Actions roles
