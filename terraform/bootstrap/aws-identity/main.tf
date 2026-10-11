module "github_identity" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/aws/github-identity?ref=2b3c0ce3590f62584ce1e284f437191cc06dfe48"

  name_prefix        = var.name_prefix
  region             = var.region
  github_subjects    = var.github_subjects
  runtime_issuer_url = var.runtime_issuer_url
  processing_regions = var.processing_regions
  ownership_tag      = var.ownership_tag
  tags               = var.tags
}

output "deployment_roles" {
  description = "Configure these as GitHub environment secrets after bootstrap approval."
  value       = module.github_identity.roles
  sensitive   = true
}

output "runtime_permissions_boundary_arn" {
  value     = module.github_identity.runtime_permissions_boundary_arn
  sensitive = true
}
