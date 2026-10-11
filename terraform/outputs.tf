output "network" {
  description = "Environment network references for subsequent gateway modules."
  sensitive   = true
  value = {
    vnet_id              = module.network.vnet_id
    subnet_ids           = module.network.subnet_ids
    private_dns_zone_ids = module.network.private_dns_zone_ids
  }
}

output "shared_identity" {
  description = "Shared identity references for later AI platform modules."
  sensitive   = true
  value       = module.identity.workloads["shared"]
}

output "apim" {
  description = "Private gateway references, ready after public access is disabled."
  sensitive   = true
  value = {
    id                  = module.apim.id
    gateway_url         = module.apim.gateway_url
    private_endpoint_id = module.apim.private_endpoint_id
  }
}

output "foundry" {
  description = "Private Foundry references for subsequent gateway API routing."
  sensitive   = true
  value = {
    id                  = module.foundry.id
    openai_endpoint     = module.foundry.openai_endpoint
    private_endpoint_id = module.foundry.private_endpoint_id
    deployments         = module.foundry.deployments
    projects            = module.foundry.projects
  }
}
output "aws_private_foundation" {
  description = "Foundation references for later private transport and APIM federation; not yet an operational inference route."
  sensitive   = true
  value = {
    vpc_id     = module.aws_network.vpc_id
    subnet_ids = module.aws_network.subnet_ids
    profiles   = module.bedrock.profiles
    endpoints  = module.bedrock.endpoints
    model_arns = module.bedrock.inference_resource_arns
  }
}

output "gcp_private_inference" {
  description = "Private Agent Platform network and approved backend metadata; transport and APIM routing are separate dependencies."
  value = {
    network_id       = module.agent_platform.network_id
    subnet_id        = module.agent_platform.subnet_id
    private_endpoint = module.agent_platform.private_endpoint
    backends         = module.agent_platform.backends
  }
  sensitive = true
}
