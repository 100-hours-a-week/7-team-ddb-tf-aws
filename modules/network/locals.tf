locals {
  nat_azs      = toset(var.nat_azs)
  nat_azs_list = tolist(local.nat_azs)
}