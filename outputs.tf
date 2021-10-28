output "random_initial_password" {
  value = random_password.initial_password.result
}

output "firewall_interface_ips" {
  value = local.firewall_interface_ips
}

output "external_lb_ips" {
  value = local.external_lb_ips
}

output "internal_lb_ips" {
  value = local.internal_lb_ips
}

output "subnet_order" {
  value = local.subnet_order
}

output "public_subnet_name" {
  value = var.public_subnet_name
}

output "private_subnet_name" {
  value = var.private_subnet_name
}

output "management_subnet_name" {
  value = var.management_subnet_name
}

output "next_hop_in_ip_address" {
  value = {
    for sn in keys(var.subnets) : sn => module.fw.internal_lb_ips[module.fw.private_subnet_name]
    if sn != module.fw.public_subnet_name
  }
}
