terraform {
  required_version = ">= 1.9"

  backend "s3" {
    bucket         = "tf-state-preview-envs"
    key            = "preview/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-lock"
    use_path_style = true
  }
}
