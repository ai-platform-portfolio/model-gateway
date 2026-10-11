module "network" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/azure/network?ref=041965b358d7196eafb6fafca5587e4710d1d16e"

  resource_group_name     = var.resource_group_name
  location                = var.location
  name                    = var.network.name
  address_space           = var.network.address_space
  subnets                 = var.network.subnets
  private_dns_zones       = var.network.private_dns_zones
  network_security_groups = var.network.network_security_groups
  route_tables            = var.network.route_tables
  tags                    = var.network.tags
}

module "identity" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/azure/identity?ref=041965b358d7196eafb6fafca5587e4710d1d16e"

  resource_group_name = var.resource_group_name
  location            = var.location
  name_prefix         = var.identity_name_prefix
  workloads = {
    shared = { federation_enabled = false }
  }
  tags       = var.network.tags
  depends_on = [module.network]
}

module "apim" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/azure/apim?ref=041965b358d7196eafb6fafca5587e4710d1d16e"

  resource_group_name        = var.resource_group_name
  location                   = var.location
  name                       = var.apim.name
  sku_name                   = var.apim.sku_name
  publisher_name             = var.publisher_name
  publisher_email            = var.publisher_email
  managed_identity_id        = module.identity.workloads["shared"].id
  integration_subnet_id      = module.network.subnet_ids[var.apim.integration_subnet_key]
  private_endpoint_subnet_id = module.network.subnet_ids[var.apim.private_endpoint_subnet_key]
  private_dns_zone_id        = module.network.private_dns_zone_ids[var.apim.private_dns_zone_key]
  timeouts                   = var.apim.timeouts
  tags                       = var.network.tags
}
