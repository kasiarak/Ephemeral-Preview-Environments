output "api_url" {
  value = module.api.api_url
}

output "function_name" {
  value = module.api.function_name
}

output "log_group_name" {
  value = module.api.log_group_name
}

output "site_bucket" {
  value = module.site.bucket_name
}

output "site_website_endpoint" {
  value = module.site.website_endpoint
}

output "alarm_name" {
  value = module.monitoring.alarm_name
}
