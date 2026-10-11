module "google_audience" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/azure/federation-audience?ref=9a4bf7ed1e790765a641dfbedcb179a76a2bda5f"

  name         = var.audience_name
  principal_id = var.azure_principal_id
}

module "github_identity" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/gcp/github-identity?ref=9a4bf7ed1e790765a641dfbedcb179a76a2bda5f"

  project_id          = var.gcp_project_id
  name                = var.name
  github_subjects     = var.github_subjects
  repository_id       = var.repository_id
  repository_owner_id = var.repository_owner_id
}

module "runtime_identity" {
  source = "git::https://github.com/ai-platform-portfolio/platform-iac.git//terraform/modules/gcp/workload-identity?ref=9a4bf7ed1e790765a641dfbedcb179a76a2bda5f"

  project_id   = var.gcp_project_id
  name         = var.name
  tenant_id    = module.google_audience.tenant_id
  principal_id = var.azure_principal_id
  issuer       = module.google_audience.issuer
  audience     = module.google_audience.audience
  role_value   = module.google_audience.role_value
  depends_on   = [module.github_identity]
}

output "deployment_providers" {
  value     = module.github_identity.providers
  sensitive = true
}

output "deployment_service_accounts" {
  value     = module.github_identity.service_accounts
  sensitive = true
}

output "runtime_token_exchange" {
  value     = module.runtime_identity.token_exchange
  sensitive = true
}

output "runtime_service_account" {
  value     = module.runtime_identity.service_account
  sensitive = true
}
