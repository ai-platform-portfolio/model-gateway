module "agent_platform" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/gcp/agent-platform?ref=9a4bf7ed1e790765a641dfbedcb179a76a2bda5f"

  project_id                   = var.gcp_project_id
  name                         = var.gcp_platform.name
  network_name                 = var.gcp_platform.network_name
  region                       = var.gcp_platform.region
  subnet_cidr                  = var.gcp_platform.subnet_cidr
  processing_location          = var.gcp_platform.processing_location
  allowed_processing_locations = var.gcp_platform.allowed_processing_locations
  models                       = var.gcp_platform.models
  labels                       = var.network.tags
}
