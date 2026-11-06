# J1 Session 4: Landing Zone as Terraform

**Author:** William Crenshaw | **Date:** November 3, 2026
**Scope:** `mg-landingzones`, `mg-lz-dev`, Azure subscription 1 | **Status:** Complete

## Objective

Bring everything built by hand in Sessions 1 to 3 under Terraform, without rebuilding or disrupting it, and prove the code matches Azure with a clean `terraform plan`.

## Approach

I imported the existing portal-built resources into Terraform state with `import` blocks (Terraform 1.5+), then edited the code until the plan showed no changes. Rebuilding would have deleted resources and policy history for no benefit. This is the same reconcile workflow I used in an earlier Terraform project.

## What the code manages

| Resource | Terraform resource |
|---|---|
| Management groups (`mg-platform`, `mg-landingzones`, `mg-lz-dev`, `mg-lz-prod`) | `azurerm_management_group` |
| Initiative `init-landing-zone-baseline` (7 policy references) | `azurerm_policy_set_definition` |
| Baseline assignment at `mg-lz-dev` | `azurerm_management_group_policy_assignment` |
| Tag inheritance assignment (Modify, managed identity) | `azurerm_management_group_policy_assignment` |
| Contributor role for the inheritance identity | `azurerm_role_assignment` |
| Monthly budget with 4 alerts | `azurerm_consumption_budget_subscription` |
| Permanent tagged group `rg-governance-dev-eus-001` | `azurerm_resource_group` |

Ten resources were imported in total. The subscription ID and owner email come from variables (`TF_VAR_...`), so no IDs are stored in the repo. State and plan files are ignored by git.

## Steps taken

1. Signed in with `az login --tenant <tenant>` (the tenant requires MFA).
2. Verified the six built-in policy definition IDs against `az policy definition list`. All matched.
3. Looked up the real names of the initiative, assignments and role assignment with the CLI.
4. Wrote `providers.tf`, `variables.tf`, `main.tf` and `imports.tf`.
5. Ran `init`, `validate` and `plan`, and fixed each difference until the plan showed only imports.
6. Applied the plan, then ran `plan` again: **No changes**.
7. Committed the code to git, after removing the plan file from the commit.

## Problems and how I fixed them

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | `AADSTS50076` on `az login` | Tenant requires MFA | `az login --tenant <tenant-id>` |
| 2 | "valid UUID" error on the management group | `subscription_ids` expects a bare ID, not `/subscriptions/<id>` | `subscription_ids = [var.subscription_id]` |
| 3 | "Cannot import non-existent remote object" (initiative, then assignments) | The portal generated random names, not the display names | Listed real names with the CLI, used them in the code and imports |
| 4 | Import ID contained a literal `<subscription id>` placeholder | I pasted a template without filling it in | Used `${var.subscription_id}` in the import ID |
| 5 | Plan wanted to **destroy and recreate the initiative** | The code had no `parameters` and the policy references had different IDs and order | Matched the portal's reference IDs, order and `parameters = {}` |
| 6 | Plan wanted to **replace the assignment and role assignment** | Azure stored resource paths in lowercase (`microsoft.management/managementgroups`) and the code produced mixed case, which forces replacement | Built the IDs with `replace(...)` to match the stored casing |
| 7 | `replace()` produced `//providers//...` | A search string that starts and ends with `/` is treated as a regex | Used `"Microsoft.Management/managementGroups"` with no outer slashes |
| 8 | Budget showed 4 alerts changed | The portal used operator `GreaterThan`, my code `GreaterThanOrEqualTo` | Changed the code to `GreaterThan` |
| 9 | Plan file staged for commit | `tfplan` contains IDs | `git rm --cached`, added `tfplan` to `.gitignore` |
| 10 | Editor squiggle on `management_group_id` | Stale editor schema; `terraform validate` passed | Trusted `validate`, ignored the squiggle |

Also: a role assignment name pasted into `main.tf` by mistake showed up as a stray line in the editor. It belongs only in the import block.

## Lessons learned

- **Read every plan for destroy and replace before applying.** Two plans wanted to destroy policy resources that other resources depend on. Reading them first prevented that.
- **A diff in a "forces replacement" field is usually formatting, not substance.** Casing, ordering and empty defaults (`{}`) caused all three replacements.
- **Resources built in the portal get generated names.** Look them up before writing imports.
- **Keep IDs out of the repo.** Use variables, and ignore state and plan files.
- **Validate, plan and the real error beat the editor's squiggles.**

## Test results

| Test | Expected | Result |
|---|---|---|
| `terraform apply` of the import plan | 10 imports, no changes to Azure | Succeeded |
| `terraform plan` after apply | No changes | **No changes** |
| Create a resource group without `cost-center` | Denied by policy | **Denied** (`RequestDisallowedByPolicy`) by "Require a tag on resource groups" in `init-landing-zone-baseline`, assignment `d051abe403ac5c8cbf45255f` at `mg-lz-dev`, with the custom non-compliance message |

## Known gaps and next steps

- `management_group_id` on `azurerm_policy_set_definition` is **deprecated** and will be removed in AzureRM v5.0. Migrate to `azurerm_management_group_policy_set_definition` (remove from state, re-import as the new type).
- Add remote state in an Azure Storage account with locking.
- Add a pipeline that runs `terraform plan` on pull requests (connects to J7).
- Add a TLS 1.2 minimum policy and a diagnostic settings policy.

## Evidence

Keep in `/evidence` (crop or redact subscription ID, tenant ID and email before publishing):

- `tf-plan-clean.png` (No changes)
- `tf-denied-rg.png` (policy denial from the re-test)
- `repo-tree.png` (file layout and git log)

## Interview story (90 seconds)

I built the guardrails by hand first so I understood each policy, then brought everything under Terraform without rebuilding it, by importing ten existing resources and editing the code until `plan` showed no changes. Along the way two plans wanted to destroy the policy initiative and its assignments. The cause was casing and ordering differences, not real changes, and I caught it by reading the plan before applying. The result is a repo anyone can review, and next I'd add remote state and a pipeline that runs plan on every pull request.
