resource "azurerm_availability_set" "as_firewall" {
  name                = "avs-${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-fw"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg-firewall.name
  managed             = false
  tags                = merge( var.tags, local.resource-tags["azurerm_availability_set"] )
}