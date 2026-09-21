output "bucket_id" {
  description = "Name of the private website bucket."
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "ARN of the private website bucket."
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "Cloudfront distribution ID."
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "Cloudfront distribution ARN."
  value       = aws_cloudfront_distribution.website.arn
}

output "website_url" {
  description = "HTTPS URL of website."
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}
