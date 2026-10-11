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
      name                              = string
      address_prefixes                  = list(string)
      network_security_group_key        = optional(string)
      route_table_key                   = optional(string)
      private_endpoint_network_policies = optional(string, "Disabled")
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

variable "ai_platform" {
  description = "Private Azure Foundry settings and approved regional model deployments."
  type = object({
    name                        = string
    location                    = string
    private_endpoint_subnet_key = string
    private_dns_zone_keys       = list(string)
    allowed_deployment_skus     = set(string)
    projects = optional(map(object({
      display_name = optional(string)
      description  = optional(string)
    })), {})
    deployments = map(object({
      format                 = optional(string, "OpenAI")
      model_name             = string
      model_version          = string
      sku_name               = optional(string, "Standard")
      capacity               = number
      version_upgrade_option = optional(string, "NoAutoUpgrade")
      rai_policy_name        = optional(string, "Microsoft.DefaultV2")
    }))
    timeouts = optional(object({
      create = optional(string, "1h")
      update = optional(string, "1h")
      delete = optional(string, "1h")
    }), {})
  })
}
variable "aws_account_id" {
  description = "Expected AWS account supplied by the workflow environment secret."
  type        = string
  sensitive   = true
}

variable "aws_platform" {
  description = "Private AWS networking and approved Bedrock profile configuration."
  type = object({
    name          = string
    region        = string
    network_name  = string
    address_space = string
    subnets = map(object({
      address_prefix    = string
      availability_zone = string
    }))
    endpoint_subnet_keys = set(string)
    allowed_client_cidrs = optional(set(string))
    processing_regions   = set(string)
    profiles = map(object({
      source_profile_id = string
      description       = optional(string)
    }))
  })
  validation {
    condition     = length(distinct([for key in var.aws_platform.endpoint_subnet_keys : var.aws_platform.subnets[key].availability_zone])) == length(var.aws_platform.endpoint_subnet_keys)
    error_message = "Each endpoint subnet must be in a distinct availability zone."
  }
}

variable "gcp_project_id" {
  description = "Expected Google project supplied by the GitHub environment secret."
  type        = string
  sensitive   = true
}

variable "gcp_platform" {
  description = "Private Gemini Enterprise Agent Platform endpoint and reviewed model approvals."
  type = object({
    name                         = string
    network_name                 = string
    region                       = string
    subnet_cidr                  = string
    processing_location          = string
    allowed_processing_locations = set(string)
    models = map(object({
      model_id             = string
      processing_locations = set(string)
    }))
  })
}
