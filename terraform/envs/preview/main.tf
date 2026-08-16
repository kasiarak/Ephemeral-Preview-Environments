terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region            = var.aws_region
  s3_use_path_style = true
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket         = "tf-state-preview-envs"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
    use_path_style = true
  }
}

locals {
  app_root = var.app_root != "" ? var.app_root : "${path.module}/../../.."
}

module "preview" {
  source            = "../../modules/preview-env"
  env_name          = "pr-${var.pr_number}"
  pr_number         = var.pr_number
  commit_sha        = var.commit_sha
  app_source_dir    = "${local.app_root}/app/api"
  web_template_path = "${local.app_root}/app/web/index.html.tftpl"
  alarm_topic_arn   = data.terraform_remote_state.shared.outputs.alarm_topic_arn
  retention_in_days = var.retention_in_days
  public_port       = var.public_port
}
