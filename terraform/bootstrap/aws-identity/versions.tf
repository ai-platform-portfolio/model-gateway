terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}
