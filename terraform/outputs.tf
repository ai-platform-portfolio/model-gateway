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
