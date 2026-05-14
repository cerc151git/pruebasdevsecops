provider "azurerm" {
  features {}
  skip_provider_registration = true  
  
}
resource "azurerm_resource_group" "devsecopsapp" {
    name = var.rg_name
    location = var.location
}