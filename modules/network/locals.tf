locals {
  az_set = toset([for s in var.public_subnets : s.az])
}