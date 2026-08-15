terraform {
  required_version = ">= 1.9"

  backend "s3" {
    bucket         = "tf-state-preview-envs"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-lock"
    use_path_style = true
  }

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

resource "aws_sns_topic" "alarms" {
  name = var.alarm_topic_name
}
