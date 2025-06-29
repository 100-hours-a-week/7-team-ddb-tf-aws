output "autoscaling_group_name" {
  value = aws_autoscaling_group.this.name
}

output "instance_name" {
  value = local.instance_name
}

output "blue_target_group_name" {
  value = aws_lb_target_group.blue.name
}

output "green_target_group_name" {
  value = try(aws_lb_target_group.green[0].name, "")
}

output "security_group_id" {
  value = aws_security_group.this.id
}
