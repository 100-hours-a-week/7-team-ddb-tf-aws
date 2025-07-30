locals {
  fe_subnet_ids = [
    for k in keys(var.private_subnets) :
    module.network.private_subnet_ids[k]
    if startswith(k, "fe")
  ]

  be_subnet_ids = [
    for k in keys(var.private_subnets) :
    module.network.private_subnet_ids[k]
    if startswith(k, "be")
  ]
}
