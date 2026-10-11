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
      name             = string
      address_prefixes = list(string)
      delegations = optional(map(object({
        service = string
        actions = list(string)
      })), {})
    }))
    private_dns_zones = map(string)
    tags              = optional(map(string), {})
  })
}
