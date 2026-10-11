variable "aws_account_id" {
  description = "Expected account ID, supplied externally."
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "github_subjects" {
  description = "Exact plan and apply environment OIDC subjects, supplied externally."
  type        = object({ plan = string, apply = string })
  sensitive   = true
}

variable "runtime_issuer_url" {
  description = "Entra federation issuer, supplied externally."
  type        = string
  sensitive   = true
}

variable "processing_regions" {
  type = set(string)
}

variable "ownership_tag" {
  type = object({ key = string, value = string })
}

variable "tags" {
  type = map(string)
}
