data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = local.state_bucket
    region = "us-east-1"
    key    = "terraform/state/common.tfstate"
  }
}

locals {
  workspace_vpcs = {
    nonprod = "VPC-EOTSS-Digital-NonProd"
    prod    = "VPC-EOTSS-Digital-Prod"
  }
  workspace_bastion_sg = {
    nonprod = "itd-dv-access-from-bastion"
    prod = "itd-pr-access-from-bastion"
  }

  // This map allows us to workaround a Terraform 0.11 problem where you can't
  // conditionally choose between two lists. Instead, we use the workspace as
  // a key to access local.alerts_topics.
  alerts_topics = {
    prod    = [data.aws_sns_topic.alerts.arn]
    nonprod = []
  }
}

module "vpc" {
  source   = "github.com/massgov/mds-terraform-common//vpcread?ref=1.0.1"
  vpc_name = local.workspace_vpcs[terraform.workspace]
}

data "aws_sns_topic" "alerts" {
  name = "infrastructure-alerts"
}

data "aws_security_group" "bastion_accessible" {
  name = local.workspace_bastion_sg[terraform.workspace]
}

module "elasticsearch" {
  source               = "./modules/elasticsearch"
  name                 = "${var.name_prefix}-es"
  vpc                  = module.vpc.vpc
  subnets              = slice(sort(tolist(module.vpc.private_subnets)), 0, 1)
  security_groups      = [data.aws_security_group.bastion_accessible.id]
  tags                 = var.tags
  create_service_role  = var.create_es_service_role
  instance_count       = var.instance_count
  instance_type        = var.instance_type
  instance_volume_size = var.instance_volume_size
  backup_bucket_arn    = "arn:aws:s3:::backup.logs.digital.mass.gov"
}

module "cluster" {
  source        = "github.com/massgov/mds-terraform-common//ecscluster?ref=1.0.20"
  name          = var.name_prefix
  vpc           = module.vpc.vpc
  subnets       = module.vpc.private_subnets
  capacity      = var.cluster_capacity
  instance_type = var.cluster_instance_type
  security_groups = [
    data.aws_security_group.bastion_accessible.id,
    module.elasticsearch.accessor_security_group,
    module.balancer.target_security_group,
    aws_security_group.cluster_member.id,
  ]
  policies = ["arn:aws:iam::748039698304:policy/EOTSSEC2PolicyforSSM"]
  schedule             = var.cluster_schedule
  instance_backup      = var.cluster_instance_backup
  instance_schedule    = var.cluster_instance_schedule
  instance_patch_group = var.cluster_instance_patch_group
  keypair              = var.keypair
  tags                 = var.tags
}

resource "aws_security_group" "cluster_member" {
  vpc_id = module.vpc.vpc

  // Cluster instances need blanket egress for accessing Acquia
  // log streams.
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

module "balancer" {
  source  = "./modules/balancer"
  name    = "${var.name_prefix}-alb"
  vpc     = module.vpc.vpc
  subnets = module.vpc.public_subnets
  waf     = data.terraform_remote_state.common.outputs.alb_cdn_waf
  tags    = var.tags
}

module "domain" {
  source        = "github.com/massgov/mds-terraform-common//domain?ref=1.0.1"
  name          = var.name_prefix
  domain_name   = var.domain
  zone          = var.domain_zone
  origin        = module.balancer.dns_name
  origin_policy = "http-only"
  cdn_token     = data.terraform_remote_state.common.outputs.alb_cdn_token
  tags          = var.tags
}

module "proxy" {
  source             = "./modules/proxy"
  name               = "${var.name_prefix}-proxy"
  cluster            = module.cluster.ecs_cluster
  target_group       = module.balancer.target_group_arn
  github_client_id   = var.GITHUB_CLIENT_ID
  github_secret      = var.GITHUB_CLIENT_SECRET
  auth_cookie_secret = var.AUTH_COOKIE_SECRET
  proxy_origin       = "https://${module.elasticsearch.elasticsearch_endpoint}"
  domain             = var.domain
  tags               = var.tags
}

data "aws_iam_policy_document" "alert_publisher" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [data.aws_sns_topic.alerts.arn]
  }
}

module "lambda_parameter_policy" {
  source        = "github.com/massgov/mds-terraform-common//chamberpolicy?ref=1.0.20"
  namespace = "${var.chamber_namespace}/*"
}

module "metrics" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.19"
  package    = "${path.module}/dist/node.zip"
  name       = "${var.name_prefix}-metricssync"
  human_name = "ELK metrics sync (${var.environment_name})"
  handler    = "metrics.handler"
  runtime    = "nodejs10.x"
  timeout    = 600
  subnets    = module.vpc.private_subnets
  security_groups = [
    module.elasticsearch.accessor_security_group,
    aws_security_group.cluster_member.id,
  ]
  iam_policies = [data.aws_iam_policy_document.publish_to_sns.json, module.lambda_parameter_policy.read_policy]
  error_topics = local.alerts_topics[terraform.workspace]
  environment = {
    variables = {
      ELASTICSEARCH = "https://${module.elasticsearch.elasticsearch_endpoint}"
      PARAMETER_NAMESPACE = "/${var.chamber_namespace}"
      ALERT_TOPIC_ARN = terraform.workspace == "prod" ? data.aws_sns_topic.alerts.arn : null
    }
  }
  schedule = {
    hourly = "rate(1 hour)"
  }

  tags = var.tags
}

module "curator" {
  source          = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.19"
  package         = "${path.module}/dist/curator.zip"
  name            = "${var.name_prefix}-curator"
  human_name      = "ELK Curator (${var.environment_name})"
  handler         = "handler.handler"
  runtime         = "python3.6"
  timeout         = 300
  subnets         = module.vpc.private_subnets
  security_groups = [module.elasticsearch.accessor_security_group]
  iam_policies    = [data.aws_iam_policy_document.publish_to_sns.json]
  error_topics    = local.alerts_topics[terraform.workspace]
  environment = {
    variables = {
      ELASTICSEARCH_ENDPOINT    = "https://${module.elasticsearch.elasticsearch_endpoint}"
      MASSGOV_ES_RETENTION_DAYS = var.massgov_es_retention_days
      OTHER_ES_RETENTION_DAYS   = var.other_es_retention_days
    }
  }
  schedule = {
    daily = "rate(1 day)"
  }
  tags = var.tags
}

module "massgov_collector" {
  source                 = "./modules/collector"
  name                   = "${var.name_prefix}-collect"
  cluster                = module.cluster.ecs_cluster
  collector_image        = var.collector_image
  elasticsearch_endpoint = module.elasticsearch.elasticsearch_endpoint
  AC_API2_KEY            = var.AC_API2_KEY
  AC_API2_SECRET         = var.AC_API2_SECRET
  ac_site                = "massgov"
  ac_environment         = "prod"
  ac_environment_id      = "26644-ff8ed1de-b8bc-48a4-b316-cd91bfa192c4"
  tags                   = var.tags
}

module "massgov_streamer" {
  source                  = "./modules/streamer"
  name                    = "${var.name_prefix}-stream"
  cluster                 = module.cluster.ecs_cluster
  AC_API2_KEY             = var.AC_API2_KEY
  AC_API2_SECRET          = var.AC_API2_SECRET
  AC_API_ENVIRONMENT_UUID = var.AC_API_ENVIRONMENT_UUID
  NR_LICENSE_KEY          = var.NR_LICENSE_KEY
  tags                    = var.tags
}

module "integrity" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.19"
  name            = "${var.name_prefix}-integrity"
  human_name      = "ELK integrity check (${var.environment_name})"
  package         = "${path.module}/dist/node.zip"
  handler         = "integrity.handler"
  runtime         = "nodejs10.x"
  timeout         = 300
  security_groups = [module.elasticsearch.accessor_security_group]
  subnets         = module.vpc.private_subnets
  iam_policies = [data.aws_iam_policy_document.publish_to_sns.json, module.lambda_parameter_policy.read_policy]
  error_topics    = local.alerts_topics[terraform.workspace]
  environment = {
    variables = {
      ELASTICSEARCH = "https://${module.elasticsearch.elasticsearch_endpoint}"
      PARAMETER_NAMESPACE = "/${var.chamber_namespace}"
      ALERT_TOPIC_ARN = terraform.workspace == "prod" ? data.aws_sns_topic.alerts.arn : null
    }
  }

  schedule = var.schedule_expression

  tags = var.tags
}

data "aws_iam_policy_document" "publish_to_sns" {
  statement {
    actions = [
      "SNS:Publish",
    ]
    resources = [data.aws_sns_topic.alerts.arn]
  }
}

module "dns_value_checker" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.19"
  package    = "${path.module}/dist/node.zip"
  name       = "${var.name_prefix}-dns-value-checker"
  human_name = "DNS value checker (${var.environment_name})"
  handler    = "dnscheck.handler"
  runtime    = "nodejs10.x"
  timeout    = 600
  subnets    = module.vpc.private_subnets
  security_groups = [
    module.elasticsearch.accessor_security_group,
    aws_security_group.cluster_member.id,
  ]
  iam_policies = [data.aws_iam_policy_document.publish_to_sns.json]
  error_topics = local.alerts_topics[terraform.workspace]
  environment = {
    variables = {
      ELASTICSEARCH = "https://${module.elasticsearch.elasticsearch_endpoint}"
      PARAMETER_NAMESPACE = "/${var.chamber_namespace}"
      ALERT_TOPIC_ARN = terraform.workspace == "prod" ? data.aws_sns_topic.alerts.arn : null
    }
  }
  schedule = {
    hourly = "rate(1 hour)"
  }

  tags = var.tags
}

data "aws_sns_topic" "cloudflare_logs" {
  name = "cloudflare-log-upload"
}

data "aws_iam_policy_document" "sns_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Subscribe",
      "s3:GetObject",
    ]
    resources = [
      data.aws_sns_topic.cloudflare_logs.arn,
      "arn:aws:s3:::cloudflare.logs.digital.mass.gov/*",
    ]
  }
}
