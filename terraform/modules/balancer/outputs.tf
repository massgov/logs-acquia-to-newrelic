output "target_group_arn" {
  value = aws_alb_target_group.default.arn
}

output "target_security_group" {
  value = aws_security_group.balancer_target.id
}

output "dns_name" {
  value = aws_alb.default.dns_name
}

