# ============================================================================
# OUTPUT VALUES
# ============================================================================

# Output the CloudFront distribution URL (this is what users will visit)
output "cloudfront_url" {
  description = "The CloudFront distribution URL for your website"
  value       = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
}

# Output the CloudFront distribution domain name
output "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

# Output the S3 bucket name
output "s3_bucket_name" {
  description = "The name of the S3 bucket storing your website"
  value       = aws_s3_bucket.website_bucket.id
}

# Output the S3 bucket ARN
output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.website_bucket.arn
}

# Output the CloudFront distribution ID
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website_distribution.id
}

# Output the S3 website endpoint (for reference, but CloudFront is preferred)
output "s3_website_endpoint" {
  description = "The S3 website endpoint (use CloudFront URL instead)"
  value       = aws_s3_bucket_website_configuration.website_bucket_config.website_endpoint
}

