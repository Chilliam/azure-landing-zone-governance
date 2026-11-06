locals {
  # Built-in policy definition IDs: verify with the az command above
  pol_require_tag      = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  pol_require_tag_rg   = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  pol_allowed_loc      = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  pol_nic_no_public_ip = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
  pol_secure_transfer  = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  pol_inherit_tag      = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"

  required_tags = ["owner", "environment", "cost-center"]
}

# ---------- Management groups ----------
resource "azurerm_management_group" "platform" {
  name         = "mg-platform"
  display_name = "mg-platform"
}

resource "azurerm_management_group" "landingzones" {
  name         = "mg-landingzones"
  display_name = "mg-landingzones"
}

resource "azurerm_management_group" "lz_dev" {
  name                       = "mg-lz-dev"
  display_name               = "mg-lz-dev"
  parent_management_group_id = azurerm_management_group.landingzones.id
  subscription_ids           = [var.subscription_id]
}

resource "azurerm_management_group" "lz_prod" {
  name                       = "mg-lz-prod"
  display_name               = "mg-lz-prod"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

# ---------- Initiative (defined at mg-landingzones) ----------
resource "azurerm_policy_set_definition" "baseline" {
  name                = "4a649c523a9153719cc875a9"
  policy_type         = "Custom"
  display_name        = "init-landing-zone-baseline"
  description         = "Baseline guardrails for landing zone subscriptions: required tags, allowed regions, no public IPs on NICs, HTTPS for storage."
  management_group_id = azurerm_management_group.landingzones.id
  parameters          = jsonencode({})

  policy_definition_reference {
    policy_definition_id = local.pol_require_tag
    reference_id         = "Require a tag on resources_1"
    parameter_values     = jsonencode({ tagName = { value = "owner" } })
  }
  policy_definition_reference {
    policy_definition_id = local.pol_require_tag_rg
    reference_id         = "Require a tag on resource groups_1"
    parameter_values     = jsonencode({ tagName = { value = "cost-center" } })
  }
  policy_definition_reference {
    policy_definition_id = local.pol_allowed_loc
    reference_id         = "Allowed locations_1"
    parameter_values     = jsonencode({ listOfAllowedLocations = { value = var.allowed_locations } })
  }
  policy_definition_reference {
    policy_definition_id = local.pol_nic_no_public_ip
    reference_id         = "Network interfaces should not have public IPs_1"
    parameter_values     = jsonencode({})
  }
  policy_definition_reference {
    policy_definition_id = local.pol_secure_transfer
    reference_id         = "Secure transfer to storage accounts should be enabled_1"
    parameter_values     = jsonencode({})
  }
  policy_definition_reference {
    policy_definition_id = local.pol_require_tag
    reference_id         = "Require a tag on resources_2"
    parameter_values     = jsonencode({ tagName = { value = "environment" } })
  }
  policy_definition_reference {
    policy_definition_id = local.pol_require_tag
    reference_id         = "Require a tag on resources_3"
    parameter_values     = jsonencode({ tagName = { value = "cost-center" } })
  }
}

# ---------- Assignments at mg-lz-dev ----------
resource "azurerm_management_group_policy_assignment" "baseline" {
  name                = "d051abe403ac5c8cbf45255f"
  display_name        = "init-landing-zone-baseline"
  management_group_id = azurerm_management_group.lz_dev.id
  # The portal stored this ID in lowercase; matching it avoids a forced replacement
  policy_definition_id = replace(azurerm_policy_set_definition.baseline.id, "Microsoft.Management/managementGroups", "microsoft.management/managementgroups")
  enforce              = true
  parameters           = jsonencode({})
  not_scopes           = []

  non_compliance_message {
    content = "Resource must meet the landing zone baseline. See the naming and tagging standard."
  }
}

resource "azurerm_management_group_policy_assignment" "inherit_tag" {
  name                 = "8a3ec967c1e75513a8403978"
  display_name         = "inherit-tag-cost-center"
  description          = "Copies the cost-center tag from the resource group to resources that lack it."
  management_group_id  = azurerm_management_group.lz_dev.id
  policy_definition_id = local.pol_inherit_tag
  location             = "eastus"

  parameters = jsonencode({ tagName = { value = "cost-center" } })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "inherit_tag_contributor" {
  scope                = replace(azurerm_management_group.lz_dev.id, "Microsoft.Management/managementGroups", "microsoft.management/managementgroups")
  role_definition_name = "Contributor"
  principal_id         = azurerm_management_group_policy_assignment.inherit_tag.identity[0].principal_id
}

# ---------- Cost governance ----------
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-landingzone-dev-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      enabled        = true
      threshold      = notification.value
      threshold_type = "Actual"
      operator       = "GreaterThan"
      contact_emails = [var.owner_email]
    }
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_emails = [var.owner_email]
  }
}

# ---------- Permanent governance resource group ----------
resource "azurerm_resource_group" "governance" {
  name     = "rg-governance-dev-eus-001"
  location = "eastus"

  tags = {
    owner       = var.owner_email
    environment = "dev"
    cost-center = var.cost_center
  }
}