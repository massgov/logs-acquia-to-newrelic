variable "name_prefix" {
  type        = string
  description = "The name prefix to use for all created resources."
}

variable "keypair" {
  type        = string
  description = "Name of SSH Keypair already registered AWS"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default     = {}
}

variable "environment_name" {
  type        = string
  description = "Short name to describe the environment. Will be used for distinguishing alerts."
}

variable "massgov_es_retention_days" {
  type        = string
  description = "Number of days to keep the 'massgov-' Elasticseach indices around."
}

variable "other_es_retention_days" {
  type        = string
  description = "Number of days to keep the non 'massgov-' Elasticseach indices around."
}

variable "domain_zone" {
  type    = string
  default = "digital.mass.gov"
}

variable "domain" {
  type = string
}

variable "create_es_service_role" {
  type        = string
  description = "Create a new service role for Elasticsearch (only needs to be done once per account)"
  default     = true
}

variable "cluster_capacity" {
  type    = string
  default = 1
}

variable "cluster_schedule" {
  type        = string
  description = "A boolean indicating whether to use ASG scheduling to manage the ECS cluster."
  default     = false
}

variable "cluster_instance_type" {
  type    = string
  default = "t3.small"
}

variable "cluster_instance_backup" {
  type = string
}

variable "cluster_instance_schedule" {
  type = string
}

variable "cluster_instance_patch_group" {
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

variable "GITHUB_CLIENT_ID" {
  type = string
}

variable "GITHUB_CLIENT_SECRET" {
  type = string
}

variable "AUTH_COOKIE_SECRET" {
  type = string
}

variable "NR_LICENSE_KEY" {
  type = string
}

variable "schedule_expression" {
  type        = map(string)
  description = "A map for the schedule expression"
  default     = {}
}

variable "instance_type" {
  type = string
}

variable "instance_count" {
  type = string
}

variable "instance_volume_size" {
  type = string
}

variable "chamber_namespace" {
  type = string
  description = "The SSM Parameter Store namespace where variables are kept for the Lambdas."
}
