locals {
  api_url = replace(module.api.api_url, "/:[0-9]+$/", ":${var.public_port}")
}

module "api" {
  source            = "../lambda-api"
  name_prefix       = var.env_name
  source_dir        = var.app_source_dir
  env_name          = var.env_name
  pr_number         = var.pr_number
  commit_sha        = var.commit_sha
  retention_in_days = var.retention_in_days
}

module "site" {
  source        = "../static-site"
  name_prefix   = var.env_name
  template_path = var.web_template_path

  template_vars = {
    env_name   = var.env_name
    pr_number  = var.pr_number
    commit_sha = var.commit_sha
    api_url    = local.api_url
  }
}

module "monitoring" {
  source          = "../monitoring"
  name_prefix     = var.env_name
  function_name   = module.api.function_name
  alarm_topic_arn = var.alarm_topic_arn
}
