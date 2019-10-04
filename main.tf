data "azurerm_client_config" "main" {}

data "azurerm_subscription" "main" {}

resource "random_id" "name" {
  count  = var.name == "" ? 1 : 0
  prefix = "terraform-"

  byte_length = 4
}

resource "azuread_application" "main" {
  name = coalesce(var.name, random_id.name[0].hex)

  available_to_other_tenants = false

  identifier_uris = [format("http://%s", var.name)]
}

resource "azuread_service_principal" "main" {
  application_id = azuread_application.main.application_id
}

resource "random_password" "main" {
  count   = var.password == "" ? 1 : 0
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "main" {
  count                = var.password != null ? 1 : 0
  service_principal_id = azuread_service_principal.main.id

  value = coalesce(var.password, random_password.main[0].result)

  end_date = var.end_date

  end_date_relative = (
    var.end_date == null ?
    "${(var.years * 24 * 365)}h" :
    null
  )
}

data "azurerm_role_definition" "main" {
  count = var.role != "" ? 1 : 0
  name  = var.role
}

resource "azurerm_role_assignment" "main" {
  count              = var.role != "" ? length(local.scopes) : 0
  scope              = local.scopes[count.index]
  role_definition_id = data.azurerm_role_definition.main[0].id
  principal_id       = azuread_service_principal.main.id
}
