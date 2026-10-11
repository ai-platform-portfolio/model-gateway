network = {
  resource_group_name = "model-gateway-network-uks-rg"
  location            = "uksouth"
  name                = "model-gateway-vnet-uks"
  address_space       = ["10.60.0.0/16"]

  subnets = {
    aks = {
      name             = "aks"
      address_prefixes = ["10.60.0.0/22"]
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
