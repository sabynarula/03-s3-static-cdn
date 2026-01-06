# ============================================================================
# S3 BUCKET FOR STATIC WEBSITE HOSTING
# ============================================================================

# Create an S3 bucket to store your website files
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "Static Website Bucket"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning for the bucket (optional - disabled by default to minimize costs)
resource "aws_s3_bucket_versioning" "website_bucket_versioning" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.website_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure the bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website_bucket_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"  # Fallback to index.html on errors
  }
}

# Block public access settings (we'll use CloudFront instead)
resource "aws_s3_bucket_public_access_block" "website_bucket_pab" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets  = true
}

# ============================================================================
# CLOUDFRONT ORIGIN ACCESS CONTROL (OAC)
# ============================================================================

# Create an Origin Access Control for CloudFront to access S3 privately
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ============================================================================
# S3 BUCKET POLICY FOR CLOUDFRONT ACCESS
# ============================================================================

# Allow CloudFront to read objects from the S3 bucket
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.website_distribution]
}

# ============================================================================
# CLOUDFRONT DISTRIBUTION
# ============================================================================

# Create CloudFront distribution to serve your website globally
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.bucket_name}"
  default_root_object = "index.html"

  # Price class determines which edge locations CloudFront uses
  # PriceClass_100 = US, Canada, Europe (cheapest)
  # PriceClass_200 = Adds Asia, Middle East, Africa
  # PriceClass_All = All locations (most expensive)
  price_class = var.cloudfront_price_class

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"  # Force HTTPS
    min_ttl                = 0
    default_ttl            = 3600   # Cache for 1 hour
    max_ttl                = 86400  # Maximum cache 24 hours
    compress               = true   # Enable compression
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"  # Allow access from all countries
    }
  }

  # Viewer certificate (CloudFront default certificate for *.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "CloudFront Distribution"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# UPLOAD WEBSITE FILES TO S3
# ============================================================================

# Upload the index.html file to S3
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html")

  # Invalidate CloudFront cache when file changes
  depends_on = [aws_cloudfront_distribution.website_distribution]
}

