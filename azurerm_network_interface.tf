resource "azurerm_network_interface" "interfaces" {
  for_each = {for interface in local.firewall_interfaces: "${interface.firewall_name}-${interface.interface_name}" => interface}
    name                            = each.key
    location                        = var.region
    resource_group_name             = azurerm_resource_group.rg-firewall.name
    enable_ip_forwarding            = true
    ip_configuration {
      name                          = each.key
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = "static"
      private_ip_address            = each.value.private_ip_address
    }
    tags                            = merge( var.tags, local.resource-tags["azurerm_network_interface"] )
}