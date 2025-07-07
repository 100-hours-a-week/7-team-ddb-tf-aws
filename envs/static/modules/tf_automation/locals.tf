locals {
  lambda_schedules = {
    for k, v in var.lambda_schedules : k => merge(
      v,
      v.action == "stop" ? {
        min_size     = 0
        desired_size = 0
        max_size     = 0
      } : var.asg_config[v.env]
    )
  }
}
