locals {
  nat_azs      = toset([for s in values(var.public_subnets) : s.az])
  nat_azs_list = tolist(local.nat_azs)
}