variable "resource_group_name" {
  description = "Shared resource group for this Model Gateway environment, created by the network module."
  type        = string
}

variable "location" {
  description = "Shared Azure deployment region for this Model Gateway environment."
  type        = string
}

variable "network" {
  description = "Fresh environment-owned network. Cloud identity and state backend identifiers are supplied externally."
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      name                       = string
      address_prefixes           = list(string)
      network_security_group_key = optional(string)
      route_table_key            = optional(string)
      delegations = optional(map(object({
        service = string
        actions = list(string)
      })), {})
    }))
    network_security_groups = optional(map(object({
      name = string
      rules = optional(map(object({
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = optional(string, "*")
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
      })), {})
    })), {})
    route_tables = optional(map(object({
      name                          = string
      bgp_route_propagation_enabled = optional(bool, true)
      routes = optional(map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      })), {})
    })), {})
    private_dns_zones = map(string)
    tags              = optional(map(string), {})
  })
}

variable "identity_name_prefix" {
  description = "Name prefix for the shared environment managed identity."
  type        = string
}

variable "apim" {
  description = "API Management settings and logical network references."
  type = object({
    name                        = string
    sku_name                    = string
    integration_subnet_key      = string
    private_endpoint_subnet_key = string
    private_dns_zone_key        = string
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  })
}

variable "publisher_name" {
  description = "APIM publisher name configured in the environment tfvars."
  type        = string
  sensitive   = true
}

variable "publisher_email" {
  description = "APIM publisher contact email configured in the environment tfvars."
  type        = string
  sensitive   = true
}
