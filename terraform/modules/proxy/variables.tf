variable "name" {
  type = string
}

variable "cluster" {
  type = string
}

variable "target_group" {
  type = string
}

variable "github_client_id" {
  type = string
}

variable "github_secret" {
  type = string
}

variable "auth_cookie_secret" {
  type = string
}

variable "proxy_origin" {
  type = string
}

variable "domain" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

