resource "azurerm_virtual_machine" "firewall" {
  for_each = { for name in local.firewall_names: name => name }
    name                = each.value
    location            = var.region
    resource_group_name = azurerm_resource_group.rg-firewall.name
    vm_size             = var.vm_size
    availability_set_id = azurerm_availability_set.as_firewall.id

    plan {
      name      = var.sku
      publisher = var.publisher
      product   = var.offer
    }

    boot_diagnostics {
      enabled = "true"
      storage_uri = "${var.storage_uri}"
    }

    storage_image_reference {
      publisher = var.publisher
      offer     = var.offer
      sku       = var.sku
      version   = var.fwversion
    }

    storage_os_disk {
      name          = "${each.value}-osDisk"
      vhd_uri       = "${azurerm_storage_account.stgacct_firewalls[each.value].primary_blob_endpoint}vhds/${each.value}-${var.offer}-${var.sku}.vhd"
      caching       = "ReadWrite"
      create_option = "FromImage"
    }

    os_profile {
      computer_name  = each.value
      admin_username = var.username
      admin_password = random_password.initial_password.result
    }

    os_profile_linux_config {
      disable_password_authentication = false
    }

    primary_network_interface_id = azurerm_network_interface.interfaces["${each.value}-eth0"].id
    network_interface_ids        = local.firewall_interface_ids[each.value]

    tags                         = merge( var.tags, local.resource-tags["azurerm_virtual_machine"] )
}

resource "random_password" "initial_password" {
  length           = 16
  special          = true
}
