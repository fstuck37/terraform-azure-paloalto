variable "region" {
  type        = string
  description = "Required : The Azure Region to deploy the VNET to"
  
  validation {
    condition = (
      contains(["eastus", "eastus2", "southcentralus", "westus2", "australiaeast", "southeastasia", "northeurope", "uksouth", "westeurope", "centralus", "northcentralus", "westus", "southafricanorth", "centralindia", "eastasia", "japaneast", "jioindiawest", "koreacentral", "canadacentral", "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth", "brazilsouth", "centralusstage", "eastusstage", "eastus2stage", "northcentralusstage", "southcentralusstage", "westusstage", "westus2stage", "asia", "asiapacific", "australia", "brazil", "canada", "europe", "global", "india", "japan", "uk", "unitedstates", "eastasiastage", "southeastasiastage", "centraluseuap", "eastus2euap", "westcentralus", "westus3", "southafricawest", "australiacentral", "australiacentral2", "australiasoutheast", "japanwest", "koreasouth", "southindia", "westindia", "canadaeast", "francesouth", "germanynorth", "norwaywest", "switzerlandwest", "ukwest", "uaecentral", "brazilsoutheast"], var.region)
    )
    error_message = "The region is not valid."
  }
}

variable "name-vars" {
  description = "Required : Map with two keys account and name. Names of elements are created based on these values."
  type = map(string)

  validation {
    condition = (
      contains(keys(var.name-vars), "account") && 
      contains(keys(var.name-vars), "name")
    )
    error_message = "The input name-vars must contain two elements account and name."
  }
}

variable "tags" {
  type        = map(string)
  description = "Optional : A map of tags to assign to the resource."
  default     = {}
}

variable "resource-tags" {
  type        = map(map(string))
  description = "Optional : A map of maps of tags to assign to specifc resources.  The key must be one of the following: azurerm_resource_group, azurerm_availability_set, azurerm_storage_account, azurerm_public_ip, azurerm_network_interface, azurerm_virtual_machine, azurerm_lb otherwise it will be ignored."
  default     = {}
}

variable "firewall_instances" {
  type = number
  description = "Optional: the number of firewall instances to deploy, default is 2"
  default = 2
}

variable "firewall_ip_base" {
  type = number
  description = "Optional: The starting IP offset for allocating IP addresses to interfaces. Default is 5."
  default = 5
}

	variable "public_subnet_name" {
	  type = string
	  description = "Required: The value must match one of the keys present in subnets and denotes the public subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to untrust."
	  default = "untrust"
	}

	variable "private_subnet_name" {
	  type = string
	  description = "Required: The value must match one of the keys present in subnets and denotes the private subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to trust."
	  default = "trust"
	}

	variable "management_subnet_name" {
	  type = string
	  description = "Required: The value must match one of the keys present in subnets and denotes the public subnet. This is used to create the hosting LB and external interface of the firewall. If this is not speicified hosting will not be enabled. Defaults to mgt."
	  default = "mgt"
	}

/*
variable "subnet_order" {
  type = list(string)
  description = "Required: The keys must match those present in the subnets variable. The values must start with the management interface, followed by any other subnets you want to utilize. This will be the number of and order of the network interfaces attached to the firewall."
  default = []
  validation {
    condition = (
      length(var.subnet_order) >= 1 &&
      length(var.subnet_order) <= 3
    )
    error_message = "The variable subnet_order must be defined."
  }
}

variable "subnet_exclude_outbound" {
  type = list(string)
  description = "Optional: Subnets to exclude from creating outbound load balancers. The keys must match keys present in subnets. For example outbound traffic would not be needed from the management or public subnets. Defaults to [pub]."
  default = ["pub"]
  validation {
    condition = (
      length(var.subnet_exclude_outbound) >= 1
    )
    error_message = "The variable subnet_order must be defined."
  }
}
*/


variable "subnets" {
  type = map(object({
    address_prefix = string
    address_prefixes = list(string)
    name = string
    id = string
  }))
  description = "Required: The subnets that the firewalls will have Interfaces on. This matches the output from the terraform-azure-vnet module"
  default = {}
}

variable "hosting_configuration" {
  type = map(object({
    domain_name_label = string
    frontend_ports = list(number)
    backend_ports = list(number)
  }))
  description = "Optional : A map of maps that define the sites hosted by the firewall. Required keys for each object are domain_name_label, frontend_ports, and backend_ports. The length of frontend_ports and backend_ports must be the same."
  default     = {}
}

variable "account_replication_type_Firewall" {
  type    = string
  default = "LRS"
}

variable "account_tier_Firewall" {
  type    = string
  default = "Standard"
}

variable "vm_size" {
  type    = string
  default = "Standard_D3_v2"
}

variable "sku" {
  type    = string
  default = "bundle2"
}

variable "offer" {
  type    = string
  default = "vmseries1"
}

variable "publisher" {
  type    = string
  default = "paloaltonetworks"
}

variable "storage_uri" {
  type    = string
}

variable "fwversion" {
  type    = string
  default = "latest"
}

variable "username" {
  type    = string
  default = "paloalto"
}

variable "fw_intlb_ports" {
  type = list(string)
  description = "List of ports for the internal load balancer rules"
  default = ["TCP|80","TCP|443","TCP|22"]
}

