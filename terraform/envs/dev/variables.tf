variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "commit_sha" {
  type    = string
  default = "unknown"
}

variable "public_port" {
  type    = number
  default = 4566
}

variable "app_root" {
  type    = string
  default = ""
}

variable "git_ref" {
  type    = string
  default = ""
}
