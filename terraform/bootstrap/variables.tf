variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket" {
  type    = string
  default = "tf-state-preview-envs"
}

variable "lock_table" {
  type    = string
  default = "tf-state-lock"
}
