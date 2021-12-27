data "template_file" "task" {
  template = file("${path.module}/src/task.json")
  vars = {
    image                   = "massgov/logs-acquia-to-newrelic:latest"
    AC_API2_KEY             = var.AC_API2_KEY
    AC_API2_SECRET          = var.AC_API2_SECRET
    AC_API_ENVIRONMENT_UUID = var.AC_API_ENVIRONMENT_UUID
    NR_LICENSE_KEY          = var.NR_LICENSE_KEY
    log_group               = aws_cloudwatch_log_group.logs.name
    log_region              = "us-east-1"
  }
}

resource "aws_ecs_task_definition" "streamer" {
  container_definitions = data.template_file.task.rendered
  family                = var.name
}

resource "aws_ecs_service" "streamer" {
  name            = var.name
  task_definition = "${aws_ecs_task_definition.streamer.family}:${max(aws_ecs_task_definition.streamer.revision)}"
  desired_count   = 1
  cluster         = var.cluster
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

