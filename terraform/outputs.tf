output "network" {
  description = "Environment network references for subsequent gateway modules."
  sensitive   = true
  value = {
    vnet_id              = module.network.vnet_id
    subnet_ids           = module.network.subnet_ids
    private_dns_zone_ids = module.network.private_dns_zone_ids
  }
}
