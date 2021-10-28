locals {
  emptymaps = [{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}]
  resource_list = ["azurerm_resource_group", "azurerm_availability_set", "azurerm_storage_account", "azurerm_public_ip", "azurerm_network_interface", "azurerm_virtual_machine", "azurerm_lb"]
  empty-resource-tags = zipmap(local.resource_list, slice(local.emptymaps, 0 ,length(local.resource_list)))
  resource-tags = merge(local.empty-resource-tags, var.resource-tags)

  subnet_order = [var.management_subnet_name, var.public_subnet_name, var.private_subnet_name]
  
  outbound_source_subnets = [var.private_subnet_name]
  
  firewall_names = flatten([
    for i in range(var.firewall_instances) : ["${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-fw${i+1}"]
  ])

  firewall_interfaces = flatten([
    for i, name in local.firewall_names : [
      for ii, subnet in local.subnet_order : {
        firewall_name      = name
        firewall_index     = i
        interface_name     = "eth${ii}"
        interface_index    = ii
        subnet_short_name  = subnet
        subnet_name        = var.subnets[subnet].name
        subnet_id          = var.subnets[subnet].id
        subnet_cidr        = var.subnets[subnet].address_prefix
        private_ip_address = "${cidrhost(var.subnets[subnet].address_prefix, var.firewall_ip_base+i) }"
      }
    ]
  ])

  firewall_interface_ips = {
    for i, name in local.firewall_names : name => {
      for ii, subnet in local.subnet_order : "eth${ii}" => {
        "private_ip_address" = azurerm_network_interface.interfaces["${name}-eth${ii}"].private_ip_address
      }
    }
  }

  firewall_interface_ids = {
    for i, name in local.firewall_names : name => flatten([
      for ii, subnet in local.subnet_order : [
        azurerm_network_interface.interfaces["${name}-eth${ii}"].id
      ]
    ])
  }

  external_lb_rules = flatten([
    for k, v in var.hosting_configuration : [
      for i, port in v["frontend_ports"] : {
        domain_name_label = v["domain_name_label"]
        rule_name         = "${v["domain_name_label"]}-${port}-${v["backend_ports"][i]}"
        frontend_port     = port
        backend_port      = v["backend_ports"][i]
        name              = k
      }
    ]
  ])
  
  external_lb_ips = {
    for k, v in var.hosting_configuration : k => {
      fqdn = azurerm_public_ip.external-ips[k].fqdn
      ip   = azurerm_public_ip.external-ips[k].ip_address
    }
  }

  internal_lb_ips = {
    for s in local.outbound_source_subnets : s => azurerm_lb.internal_lbs[s].private_ip_address
  }

}
