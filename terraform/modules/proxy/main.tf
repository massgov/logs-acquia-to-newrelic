data "template_file" "proxy_task" {
  template = file("${path.module}/src/task.json")
  vars = {
    client_id     = var.github_client_id
    client_secret = var.github_secret
    cookie_secret = var.auth_cookie_secret
    origin        = var.proxy_origin
    base_path     = "https://${var.domain}"
    log_group     = aws_cloudwatch_log_group.proxy.name
    log_region    = "us-east-1"
  }
}

resource "aws_ecs_task_definition" "proxy" {
  container_definitions = data.template_file.proxy_task.rendered
  family                = var.name
}

resource "aws_ecs_service" "proxy" {
  name            = var.name
  task_definition = "${aws_ecs_task_definition.proxy.family}:${max(aws_ecs_task_definition.proxy.revision)}"
  desired_count   = 1
  cluster         = var.cluster
  load_balancer {
    target_group_arn = var.target_group
    container_name   = "proxy"
    container_port   = 4180
  }
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

