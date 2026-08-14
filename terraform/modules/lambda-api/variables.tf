variable "name_prefix" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumerics or hyphens and start with an alphanumeric."
  }
}

variable "source_dir" {
  type = string
}

variable "env_name" {
  type = string
}

variable "pr_number" {
  type    = string
  default = ""
}

variable "commit_sha" {
  type    = string
  default = "unknown"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "handler.lambda_handler"
}

variable "timeout" {
  type    = number
  default = 10
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "retention_in_days" {
  type    = number
  default = 3

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.retention_in_days
    )
    error_message = "retention_in_days must be one of the values CloudWatch Logs accepts."
  }
}
