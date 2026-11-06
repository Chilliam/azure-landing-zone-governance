#import {
#  to = azurerm_management_group.platform
 # id = "/providers/Microsoft.Management/managementGroups/mg-platform"
#}
#import {
#  to = azurerm_management_group.landingzones
#  id = "/providers/Microsoft.Management/managementGroups/mg-landingzones"
#}
#import {
 # to = azurerm_management_group.lz_dev
  #id = "/providers/Microsoft.Management/managementGroups/mg-lz-dev"
#}
#import {
#  to = azurerm_management_group.lz_prod
 # id = "/providers/Microsoft.Management/managementGroups/mg-lz-prod"
#}
#import {
 # to = azurerm_policy_set_definition.baseline
  #id = "/providers/Microsoft.Management/managementGroups/mg-landingzones/providers/Microsoft.Authorization/policySetDefinitions/4a649c523a9153719cc875a9"
#}
#import {
 # to = azurerm_management_group_policy_assignment.baseline
  #id = "/providers/Microsoft.Management/managementGroups/mg-lz-dev/providers/Microsoft.Authorization/policyAssignments/d051abe403ac5c8cbf45255f"
#}
#import {
 # to = azurerm_management_group_policy_assignment.inherit_tag
  #id = "/providers/Microsoft.Management/managementGroups/mg-lz-dev/providers/Microsoft.Authorization/policyAssignments/8a3ec967c1e75513a8403978"
#}
#import {
 # to = azurerm_resource_group.governance
  #id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-governance-dev-eus-001"
#}
#import {
 # to = azurerm_consumption_budget_subscription.monthly
  #id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Consumption/budgets/budget-landingzone-dev-monthly"
#}
#import {
  #to = azurerm_role_assignment.inherit_tag_contributor
  #id = "/providers/Microsoft.Management/managementGroups/mg-lz-dev/providers/Microsoft.Authorization/roleAssignments/<role-assignment-guid>"
#}