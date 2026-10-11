resource_group_name = "model-gateway-uks-rg"
location            = "uksouth"

network = {
  name          = "model-gateway-vnet-uks"
  address_space = ["10.60.0.0/16"]

  subnets = {
    apim = {
      name             = "apim"
      address_prefixes = ["10.60.0.0/24"]
      delegations = {
        apim = {
          service = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    private_endpoints = {
      name             = "private-endpoints"
      address_prefixes = ["10.60.4.0/24"]
    }
  }

  private_dns_zones = {}
  tags = {
    project     = "model-gateway"
    environment = "portfolio"
    managed_by  = "terraform"
  }
}
