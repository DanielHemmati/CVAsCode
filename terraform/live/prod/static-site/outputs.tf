output "bucket_id" {
  description = "Name of the private bucket that stores the resume assets."
  value       = module.static_site.bucket_id
}

output "bucket_arn" {
  description = "ARN of the private bucket that stores the resume assets."
  value       = module.static_site.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "ID of the resume CloudFront distribution."
  value       = module.static_site.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the resume CloudFront distribution."
  value       = module.static_site.cloudfront_distribution_arn
}

output "website_url" {
  description = "HTTPS URL using the default CloudFront domain."
  value       = module.static_site.website_url
}
