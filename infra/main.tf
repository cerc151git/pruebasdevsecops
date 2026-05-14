provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "devsecopsapp" {
    name = var.rg_name
    location = var.location
}

resource "azurerm_service_plan" "serviceplan_web" {
    name = "webprueba-plan"
    resource_group_name = azurerm_resource_group.devsecopsapp.name
    location = azurerm_resource_group.devsecopsapp.location
    os_type = "Linux"
    sku_name = "D1"
}

resource "azurerm_linux_web_app" "paginaprueba" {
    name = "paginapruebadevsecops"
    resource_group_name = azurerm_resource_group.devsecopsapp.name
    location = azurerm_resource_group.devsecopsapp.location
    service_plan_id = azurerm_service_plan.serviceplan_web.id
    site_config {
      always_on = false
      application_stack {
        docker_image_name = var.imagencontenedor
        docker_registry_url = "https://index.docker.io"
      }
    }
}
