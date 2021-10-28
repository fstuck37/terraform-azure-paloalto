/* Internal Load Balancers */
resource "azurerm_lb" "internal_lbs" {
  for_each = { for s in local.outbound_source_subnets: s => s }
    name                            = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-${each.value}-lb"
    location                        = var.region
    resource_group_name             = azurerm_resource_group.rg-firewall.name
    frontend_ip_configuration {
      name                          = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-${each.value}-lb"
      subnet_id                     = var.subnets[each.value].id
      private_ip_address_allocation = "static"
      private_ip_address            = cidrhost(var.subnets[each.value].address_prefix, pow(2, 32-tonumber((split("/",var.subnets[each.value].address_prefix))[1]))-2)
    }
    tags                            = merge( var.tags, local.resource-tags["azurerm_lb"] )
}

resource "azurerm_lb_backend_address_pool" "outbound_pools" {
  for_each = { for s in local.outbound_source_subnets: s => s }
    name                = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-${each.value}-pool"
    loadbalancer_id     = azurerm_lb.internal_lbs[each.value].id
}

resource "azurerm_lb_probe" "fw_internal_lb_probe" {
  for_each = { for s in local.outbound_source_subnets: s => s }
    resource_group_name = azurerm_resource_group.rg-firewall.name
    loadbalancer_id     = azurerm_lb.internal_lbs[each.value].id
    name                = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-${each.value}-probe"
    port                = 22
}

resource "azurerm_network_interface_backend_address_pool_association" "interfaces" {
  for_each = { for s in local.outbound_source_subnets: "${local.firewall_interfaces[s].firewall_name}-${local.firewall_interfaces[s].interface_name}"=>local.firewall_interfaces }
    network_interface_id    = azurerm_network_interface.interfaces["${each.value.firewall_name}-${each.value.interface_name}"].id
    ip_configuration_name   = "${each.value.firewall_name}-${each.value.interface_name}"
    backend_address_pool_id = azurerm_lb_backend_address_pool.outbound_pools[each.value.subnet_short_name].id
}





/* ******************** External Load Balancer ******************** */
resource "azurerm_lb" "external_lb" {
  count                    = contains(local.subnet_order, var.public_subnet_name) && length(keys(var.hosting_configuration)) > 0 ? 1 : 0 
  name                     = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-extlb"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg-firewall.name

  dynamic "frontend_ip_configuration" {
    for_each = var.hosting_configuration
    content {
      name                 = frontend_ip_configuration.value["domain_name_label"]
      public_ip_address_id = azurerm_public_ip.external-ips[frontend_ip_configuration.key].id
    }
  }

  tags                     = merge( var.tags, local.resource-tags["azurerm_lb"] )
}

resource "azurerm_lb_backend_address_pool" "external_pool" {
  count               = contains(local.subnet_order, var.public_subnet_name) && length(keys(var.hosting_configuration)) > 0 ? 1 : 0 
  loadbalancer_id     = azurerm_lb.external_lb[0].id
  name                = "${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-extlb"
}

resource "azurerm_network_interface_backend_address_pool_association" "external_interfaces" {
  for_each = {for interface in local.firewall_interfaces: "${interface.firewall_name}-${interface.interface_name}"=>interface
    if interface["subnet_short_name"] == var.public_subnet_name && contains(local.subnet_order, var.public_subnet_name) && length(keys(var.hosting_configuration)) > 0
  }
    network_interface_id    = azurerm_network_interface.interfaces["${each.value.firewall_name}-${each.value.interface_name}"].id
    ip_configuration_name   = "${each.value.firewall_name}-${each.value.interface_name}"
    backend_address_pool_id = azurerm_lb_backend_address_pool.external_pool[0].id
}

resource "azurerm_lb_probe" "external_lb_probe" {
  count               = contains(local.subnet_order, var.public_subnet_name) && length(keys(var.hosting_configuration)) > 0 ? 1 : 0 
  resource_group_name = azurerm_resource_group.rg-firewall.name
  loadbalancer_id     = azurerm_lb.external_lb[0].id
  name                = "external_lb_probe_ssh_probe"
  port                = 22
}

resource "azurerm_public_ip" "external-ips" {
  for_each = var.hosting_configuration
    name                    = each.value["domain_name_label"]
    location                = var.region
    resource_group_name     = azurerm_resource_group.rg-firewall.name
    domain_name_label       = each.value["domain_name_label"]
    idle_timeout_in_minutes = "4"
    allocation_method       = "Static"
    tags                    = merge( var.tags, local.resource-tags["azurerm_public_ip"] )
}

resource "azurerm_lb_rule" "lb-rules" {
  for_each = {for rule in local.external_lb_rules: rule["rule_name"] => rule}
    resource_group_name            = azurerm_resource_group.rg-firewall.name
    loadbalancer_id                = azurerm_lb.external_lb[0].id
    name                           = each.value["rule_name"]
    protocol                       = "Tcp"
    frontend_port                  = each.value["frontend_port"]
    backend_port                   = each.value["backend_port"]
    frontend_ip_configuration_name = each.value["domain_name_label"]
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_pool[0].id]
    probe_id                       = azurerm_lb_probe.external_lb_probe[0].id
    load_distribution              = "SourceIPProtocol"
}