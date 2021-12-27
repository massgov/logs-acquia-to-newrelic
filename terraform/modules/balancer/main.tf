resource "aws_alb" "default" {
  name            = "${var.name}-alb"
  security_groups = [aws_security_group.balancer.id]
  subnets         = var.subnets

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
  //  access_logs {
  //    bucket = "${var.log_bucket}"
  //    prefix = "${var.name_prefix}"
  //    enabled = true
  //  }
}

// @todo: Enable access logs and WAF.
resource "aws_wafregional_web_acl_association" "default_waf" {
  count        = var.waf == "" ? 0 : 1
  resource_arn = aws_alb.default.arn
  web_acl_id   = var.waf
}

resource "aws_alb_listener" "default" {
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }
  load_balancer_arn = aws_alb.default.arn
  port              = 80
}

resource "aws_alb_target_group" "default" {
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc
  deregistration_delay = 20

  health_check {
    path              = "/ping"
    healthy_threshold = 2
    interval          = 10
  }
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_security_group" "balancer" {
  name   = "${var.name}-alb"
  vpc_id = var.vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow egress to all ephemeral ports.
  egress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.balancer_target.id]
  }
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_security_group" "balancer_target" {
  name   = "${var.name}-target"
  vpc_id = var.vpc
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-target"
    },
  )
}

resource "aws_security_group_rule" "balancer_target_ingress" {
  # Allow ingress on all ephemeral ports.
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.balancer_target.id
  source_security_group_id = aws_security_group.balancer.id
  type                     = "ingress"
}

