resource "azurerm_resource_group" "rg-firewall" {
  name     = "rg-${var.name-vars["account"]}-${var.region}-${var.name-vars["name"]}-fw"
  location = var.region
  tags     = merge( var.tags, local.resource-tags["azurerm_resource_group"] )
}


