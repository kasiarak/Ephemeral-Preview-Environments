output "api_url" {
  value = module.env.api_url
}

output "site_bucket" {
  value = module.env.site_bucket
}

output "function_name" {
  value = module.env.function_name
}

output "log_group_name" {
  value = module.env.log_group_name
}

output "git_ref" {
  value = var.git_ref
}
