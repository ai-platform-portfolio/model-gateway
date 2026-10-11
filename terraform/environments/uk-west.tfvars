resource_group_name = "model-gateway-ukw-rg"
location            = "ukwest"

network = {
  name          = "model-gateway-vnet-ukw"
  address_space = ["10.60.0.0/16"]

  subnets = {
    apim = {
      name                       = "apim"
      address_prefixes           = ["10.60.0.0/24"]
      network_security_group_key = "apim"
      delegations = {
        apim = {
          service = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    foundry = {
      name                              = "foundry-private-endpoints"
      address_prefixes                  = ["10.60.5.0/24"]
      network_security_group_key        = "foundry"
      private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
    }
    private_endpoints = {
      name                              = "private-endpoints"
      address_prefixes                  = ["10.60.4.0/24"]
      network_security_group_key        = "private_endpoints"
      private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
    }
  }

  network_security_groups = {
    apim = {
      name = "model-gateway-apim-nsg-ukw"
      rules = {
        key_vault_https = {
          priority                   = 100
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "10.60.0.0/24"
          destination_address_prefix = "AzureKeyVault"
        }
        entra_https = {
          priority                   = 110
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "10.60.0.0/24"
          destination_address_prefix = "AzureActiveDirectory"
        }
        foundry_https = {
          priority                   = 120
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "10.60.0.0/24"
          destination_address_prefix = "10.60.5.0/24"
        }
        deny_other_egress = {
          priority                   = 4096
          direction                  = "Outbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    foundry = {
      name = "model-gateway-foundry-nsg-ukw"
      rules = {
        apim_https = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "10.60.0.0/24"
          destination_address_prefix = "10.60.5.0/24"
        }
        deny_unapproved_clients = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        deny_new_outbound_connections = {
          priority                   = 4096
          direction                  = "Outbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    private_endpoints = {
      name = "model-gateway-private-endpoints-nsg-ukw"
      rules = {
        deny_unapproved_clients = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        deny_new_outbound_connections = {
          priority                   = 4096
          direction                  = "Outbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }

  route_tables = {}
  private_dns_zones = {
    apim              = "privatelink.azure-api.net"
    foundry_openai    = "privatelink.openai.azure.com"
    foundry_services  = "privatelink.services.ai.azure.com"
    foundry_cognitive = "privatelink.cognitiveservices.azure.com"
  }
  tags = {
    project     = "model-gateway"
    environment = "portfolio"
    managed_by  = "terraform"
  }
}

identity_name_prefix = "model-gateway-ukw"

apim = {
  name                        = "model-gateway-apim-ukw"
  sku_name                    = "StandardV2_1"
  integration_subnet_key      = "apim"
  private_endpoint_subnet_key = "private_endpoints"
  private_dns_zone_key        = "apim"
}

publisher_name  = "Model Gateway Demo"
publisher_email = "publisher@example.com"

ai_platform = {
  name                        = "model-gateway-foundry-uks"
  location                    = "uksouth"
  private_endpoint_subnet_key = "foundry"
  private_dns_zone_keys       = ["foundry_openai", "foundry_services", "foundry_cognitive"]
  allowed_deployment_skus     = ["Standard"]

  projects = {
    model-gateway = {
      display_name = "Model Gateway"
      description  = "Private regional model inference for Model Gateway."
    }
  }

  deployments = {
    chat = {
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
      sku_name      = "Standard"
      capacity      = 10
    }
  }
}
aws_platform = {
  name          = "model-gateway-bedrock"
  region        = "eu-west-2"
  network_name  = "model-gateway-vpc-london"
  address_space = "10.70.0.0/16"

  subnets = {
    endpoints_a = { address_prefix = "10.70.0.0/24", availability_zone = "eu-west-2a" }
    endpoints_b = { address_prefix = "10.70.1.0/24", availability_zone = "eu-west-2b" }
  }
  endpoint_subnet_keys = ["endpoints_a", "endpoints_b"]

  processing_regions = [
    "eu-central-1",
    "eu-north-1",
    "eu-south-1",
    "eu-south-2",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
  ]

  profiles = {
    claude_sonnet = {
      source_profile_id = "eu.anthropic.claude-sonnet-5-5"
      description       = "Model Gateway Claude inference within the reviewed UK and EU processing boundary."
    }
  }
}
