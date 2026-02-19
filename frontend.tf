# 1. Bucket de S3 para el sitio web (HTML, JS, CSS)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "mi-frontend-app-${random_id.bucket_suffix.hex}" # Nombre único
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Origin Access Control (solo CloudFront pueda leer el S3)
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. Distribución de CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3-Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "Frontend-CDN" }
}