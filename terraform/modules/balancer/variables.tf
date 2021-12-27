variable "name" {
  type = string
}

variable "vpc" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "waf" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all instances."
  default     = {}
}

