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

  route_tables      = {}
  private_dns_zones = { apim = "privatelink.azure-api.net" }
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
