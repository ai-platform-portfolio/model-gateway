variable "name" {
  description = "Prefix for Google deployment and runtime identities."
  type        = string
}

variable "audience_name" {
  description = "Entra application name for the dedicated Google federation audience."
  type        = string
}

variable "gcp_project_id" {
  description = "Expected existing Google project, supplied externally."
  type        = string
  sensitive   = true
}

variable "azure_principal_id" {
  description = "Existing shared managed identity object ID, supplied externally."
  type        = string
  sensitive   = true
}

variable "github_subjects" {
  description = "Exact customized central-plan and central-apply GitHub OIDC subjects."
  type        = map(string)
  sensitive   = true
}

variable "repository_id" {
  description = "Immutable GitHub repository ID, supplied externally."
  type        = string
  sensitive   = true
}

variable "repository_owner_id" {
  description = "Immutable GitHub organization ID, supplied externally."
  type        = string
  sensitive   = true
}
