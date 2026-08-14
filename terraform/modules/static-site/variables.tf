variable "name_prefix" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumerics or hyphens and start with an alphanumeric."
  }
}

variable "template_path" {
  type = string
}

variable "template_vars" {
  type    = map(string)
  default = {}
}
