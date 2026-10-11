terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.6, < 9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.10, < 4.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "google" {
  project = var.gcp_project_id
}

provider "azuread" {}
