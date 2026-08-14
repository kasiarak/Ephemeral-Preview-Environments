output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}
