output "api_url" {
  value = module.preview.api_url
}

output "git_ref" {
  value = var.git_ref
}

output "site_bucket" {
  value = module.preview.site_bucket
}

output "function_name" {
  value = module.preview.function_name
}

output "log_group_name" {
  value = module.preview.log_group_name
}

output "alarm_name" {
  value = module.preview.alarm_name
}
