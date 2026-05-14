provider "azurerm" {
  features {}

}
resource "azurerm_resource_group" "devsecopsapp" {
    name = var.rg_name
    location = var.location
}
