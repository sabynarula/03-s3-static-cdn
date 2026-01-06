variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket (must be globally unique)"
  type        = string
  # You can set a default or pass it via terraform.tfvars or command line
  # Example: terraform apply -var="bucket_name=my-unique-bucket-name-12345"
}

variable "cloudfront_price_class" {
  description = "The price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe (cheapest option)

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, or PriceClass_All"
  }
}

variable "enable_s3_versioning" {
  description = "Enable versioning on S3 bucket (may incur additional storage costs)"
  type        = bool
  default     = false # Set to false to minimize costs for free tier
}