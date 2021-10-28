resource "azurerm_public_ip" "fw-ip" {
  for_each = { for name in local.firewall_names: name => name }
    name                    = "pubip-${each.value}"
    location                = var.region
    resource_group_name     = azurerm_resource_group.rg-firewall.name
    domain_name_label       = "pubip-${each.value}"
    idle_timeout_in_minutes = 4
    allocation_method       = "Static"
    tags                    = merge( var.tags, local.resource-tags["azurerm_public_ip"] )
}