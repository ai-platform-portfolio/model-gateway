module "aws_network" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/aws/network?ref=742df5302db2697fbb10efba5247405babcd2bfc"

  name          = var.aws_platform.network_name
  address_space = var.aws_platform.address_space
  subnets       = var.aws_platform.subnets
  tags          = var.network.tags
}

module "bedrock" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/aws/bedrock?ref=40bd4384fb4ef457f087e8f39189e96f42096197"

  name                 = var.aws_platform.name
  region               = var.aws_platform.region
  vpc_id               = module.aws_network.vpc_id
  endpoint_subnet_ids  = [for key in var.aws_platform.endpoint_subnet_keys : module.aws_network.subnet_ids[key]]
  allowed_client_cidrs = var.aws_platform.allowed_client_cidrs != null ? var.aws_platform.allowed_client_cidrs : var.network.subnets[var.apim.integration_subnet_key].address_prefixes
  processing_regions   = var.aws_platform.processing_regions
  profiles             = var.aws_platform.profiles
  tags                 = var.network.tags
}
