variable "env_name" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.env_name))
    error_message = "env_name must be 1-32 lowercase alphanumerics or hyphens and start with an alphanumeric."
  }
}

variable "pr_number" {
  type    = string
  default = ""
}

variable "commit_sha" {
  type    = string
  default = "unknown"
}

variable "app_source_dir" {
  type = string
}

variable "web_template_path" {
  type = string
}

variable "alarm_topic_arn" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 3
}

variable "public_port" {
  type    = number
  default = 4566
}

variable "memory_size" {
  type    = number
  default = 128
}
