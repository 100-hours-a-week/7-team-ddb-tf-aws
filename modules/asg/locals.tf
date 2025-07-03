locals {
  role_name           = "${var.component}-ssm-role-${var.env}"
  instance_profile    = "${var.component}-instance-profile-${var.env}"
  security_group_name = "${var.component}-sg-${var.env}"
  target_group_name   = "${var.component}-tg-${var.env}"
  launch_template     = "${var.component}-lt-${var.env}"
  asg_name            = "${var.component}-asg-${var.env}"
  volume_name         = "${var.component}-volume-${var.env}"
  instance_name       = "${var.component}-instance-${var.env}"
  scaling_policy_name = "${var.component}-scaling-${var.env}"
  monitoring-sg       = "${var.component}-mon-sg-${var.env}"
}

# 기본 정책 Attach (SSM, CodeDeploy, ECR)
locals {
  default_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

locals {
  allow_port_rules = flatten([
    for cidr, ports in var.allow_port : [
      for port in ports : {
        cidr = cidr
        port = port
      }
    ]
  ])
}