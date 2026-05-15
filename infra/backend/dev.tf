terraform {
  backend "azurerm" {
    storage_account_name = "saterraformdevsecops"
    container_name = "terraform"
    key = "statedev.tfstate"
  }
}
