variable "name" {
  type = string
}

variable "cluster" {
  type = string
}

variable "AC_API2_KEY" {
  type = string
}

variable "AC_API2_SECRET" {
  type = string
}

variable "AC_API_ENVIRONMENT_UUID" {
  type = string
}

variable "NR_LICENSE_KEY" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

