resource "azurerm_storage_account" "stgacct_firewalls" {
  for_each = { for name in local.firewall_names: name => name }
    name                     = "stact${lower(substr(md5(each.value), 0 , 16))}"
    resource_group_name      = azurerm_resource_group.rg-firewall.name
    location                 = var.region
    account_replication_type = var.account_replication_type_Firewall
    account_tier             = var.account_tier_Firewall
    account_kind             = "Storage"
    tags                     = merge( var.tags, local.resource-tags["azurerm_storage_account"] )
}

  
