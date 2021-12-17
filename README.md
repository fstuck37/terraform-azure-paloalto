Azure VNET
=============

This module deploys one or more Palo Alto Firewalls in an Azure VNET.

The goal of this project is to provide a streamlined, simple Terraform script to deploy Palo Altos in Azure.

Note: you must accept the license before using this module.
```

set AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1
az login
az vm image terms accept --offer vmseries1 --publisher paloaltonetworks --plan bundle1
az vm image terms accept --offer vmseries1 --publisher paloaltonetworks --plan bundle2
az vm image terms accept --offer vmseries1 --publisher paloaltonetworks --plan byol
```


Example
------------
```
module "vnet" {
  source = "git::https://github.com/fstuck37/terraform-azure-vnet.git"
  log-storage-account = var.log-storage-account
  region = var.region
  name-vars = var.name-vars
  vnet-cidrs = var.vnet-cidrs
  subnets = var.subnets  
  domain_name_servers = var.domain_name_servers
  tags = var.tags
}

variable "log-storage-account" {
  default = "/subscriptions/12345678-abcd-1234-def1-1234567890ab/resourceGroups/rg_storageaccount/providers/Microsoft.Storage/storageAccounts/logsexample"
}

variable "region" {
  default = "eastus2"
}

variable "name-vars" {
  type = map(string)
  default = {
    account = "dev"
    name    = "poc"
  }
}

variable "vnet-cidrs" {
  type = list(string)
  default = ["172.16.0.0/23"]
}

variable "subnets" {
  type = map(list(string))
  default = {
    pub   = ["172.16.0.0/25"]
    trust = ["172.16.1.0/24"]
    mgt   = ["172.16.0.128/25"]
  }
}

variable "domain_name_servers" {
  type = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

module "fw" {
  source = "git::https://github.com/fstuck37/terraform-azure-paloalto.git"
  region = var.region
  storage_uri             = "https://testaccountlogsa.blob.core.windows.net/"
  name-vars               = var.name-vars
  subnets                 = module.vnet.subnets
  subnet_order            = var.subnet_order
  subnet_exclude_outbound = var.subnet_exclude_outbound
  public_subnet_name      = var.public_subnet_name
  hosting_configuration   = var.hosting_configuration
}

variable "subnet_order" {
  type = list(string)
  default = ["mgt", "pub", "trust"]
}

variable "subnet_exclude_outbound" {
  type = list(string)
  default = [ "mgt", "pub",]
}

variable "public_subnet_name" {
  default = "pub"
}

variable "hosting_configuration" {
  default     = {
    geek37 = {
      domain_name_label = "pubip-geek37-com"
      frontend_ports = [80, 443]
      backend_ports = [18001, 18002]
    }
  }
}
```

Argument Reference
------------
   * **region** - Required : The Azure Region to deploy the VNET to.
   * **name-vars** - Required : Map with two keys account and name. Names of elements are created based on these values.
   * **tags** - Optional : A map of tags to assign to the resource.
   * **resource-tags** - Optional : A map of maps of tags to assign to specifc resources.  The key must be one of the following: azurerm_resource_group, azurerm_availability_set, azurerm_storage_account, azurerm_public_ip, azurerm_network_interface, azurerm_virtual_machine, azurerm_lb otherwise it will be ignored.
   * **firewall_instances** - Optional: The number of firewall instances to deploy, default is 2.
   * **firewall_ip_base** - Optional: The starting IP offset for allocating IP addresses to interfaces. Default is 5.
   * **public_subnet_name** - Required: The value must match one of the keys present in subnets and denotes the public subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to untrust.
   * **private_subnet_name** - Required: The value must match one of the keys present in subnets and denotes the private subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to trust.
   * **management_subnet_name** - Required: The value must match one of the keys present in subnets and denotes the public subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to mgt.


   * **subnets** - Required: The subnets that the firewalls will have Interfaces on. This matches the output from the terraform-azure-vnet module
   * **hosting_configuration** - Optional : A map of maps that define the sites hosted by the firewall. Required keys for each object are domain_name_label, frontend_ports, and backend_ports. The length of frontend_ports and backend_ports must be the same.
   * **subnet_order** - Required: The keys must match keys present in subnets. The values must start with the management interface,followed by any other subnets you want to utilize. This will be the number of and order of the network interfaces attached to the firewall. So typically you would want to mgt, public, trust, dmz1, etc.
   * **subnet_exclude_outbound** - Optional: Subnets to exclude from creating outbound load balancers. The keys must match keys present in subnets. For example outbound traffic would not be needed from the management or public subnets. Defaults to [pub].

   * **account_replication_type_Firewall** - Optional: Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Changing this forces a new resource to be created when types LRS, GRS and RAGRS are changed to ZRS, GZRS or RAGZRS and vice versa.
   
   * **account_tier_Firewall** - (Required) Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created.
   * **vm_size** - (Required) Specifies the size of the Virtual Machine. Defaults to Standard_D3_v2.
   * **sku** - (Required) Specifies the name of the image from the marketplace. Options are bundle1, bundle2, byol. Defaults to bundle2
   * **offer** - (Required) Specifies the product of the image from the marketplace. Defaults to vmseries1.
   * **publisher** - (Required) Specifies the publisher of the image. Defaults to paloaltonetworks.
   * **storage_uri** - (Required) The Storage Account's Blob Endpoint which should hold the virtual machine's diagnostic files.
   * **fwversion** - (Optional) Specifies the version of the image used to create the virtual machine. Changing this forces a new resource to be created. Defaults to latest.
   * **username** - (Optional) Specifies the initial username to use to connect to the firewall. Defaults to paloalto.
   * **fw_intlb_ports** - List of protocol|ports for the internal load balancer rules. This must include all protocol|port pairs permitted through the firewall. The default is ["TCP|80","TCP|443","TCP|22"]
s   * **internal_lb_sku** - (Optional) The SKU of the Azure Load Balancer. Accepted values are Basic, Standard. Defaults to Standard

Output Reference
------------
   * **random_initial_password** - The initial random password. This should be changed once the firewall is setup. 
   * **firewall_interface_ips** - The Firewall's interfaces and IPs.
   * **external_lb_ips** - The external Load Balancer IPs and FQDNs
   * **internal_lb_ips** - IPs of the Internal Load Balancers which can be used in the terraform-azure-vnet module to set the value of set_subnet_specific_next_hop_in_ip_address
