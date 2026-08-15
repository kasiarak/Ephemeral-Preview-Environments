variable "pr_number" {
  type = string

  validation {
    condition     = can(regex("^[0-9]+$", var.pr_number))
    error_message = "pr_number must be a positive integer."
  }
}

variable "commit_sha" {
  type    = string
  default = "unknown"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "retention_in_days" {
  type    = number
  default = 3
}
