module "network" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/network?ref=fd9f0f3287e84d67781db363ab3820c2e8a57d17"

  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.network.name
  address_space       = var.network.address_space
  subnets             = var.network.subnets
  private_dns_zones   = var.network.private_dns_zones
  tags                = var.network.tags
}
