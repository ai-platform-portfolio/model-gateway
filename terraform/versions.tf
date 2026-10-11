terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.6, < 9.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.13, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "aws" {
  region              = var.aws_platform.region
  allowed_account_ids = [var.aws_account_id]
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_platform.region
}
