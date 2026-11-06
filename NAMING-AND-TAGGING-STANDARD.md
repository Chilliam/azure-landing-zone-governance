# Azure Naming and Tagging Standard

**Owner:** William Crenshaw | **Version:** 1.1 | **Last updated:** October 31, 2026
**Applies to:** all resources in management groups `mg-lz-dev` and `mg-lz-prod`

## 1. Purpose

Consistent names and tags make resources easy to find, filter, bill and clean up. This standard is enforced by the `init-landing-zone-baseline` policy initiative where Azure Policy allows it.

## 2. Naming pattern

```
<type>-<workload>-<env>-<region>-<instance>
```

Example: `rg-webapp-dev-eus-001`

| Part | Values | Notes |
|---|---|---|
| type | prefix from table in section 3 | Required |
| workload | short app or function name, e.g. `webapp`, `hub`, `platform` | 3 to 10 characters |
| env | `dev`, `test`, `prod` | Required |
| region | `eus` (East US), `eus2` (East US 2) | Only approved regions |
| instance | `001`, `002`, ... | Three digits |

## 3. Resource prefixes

| Resource | Prefix | Example | Notes |
|---|---|---|---|
| Management group | `mg-` | `mg-lz-prod` | |
| Subscription | `sub-` | `sub-lz-dev-001` | |
| Resource group | `rg-` | `rg-webapp-dev-eus-001` | |
| Virtual network | `vnet-` | `vnet-hub-prod-eus-001` | |
| Subnet | `snet-` | `snet-app-prod-eus-001` | |
| Network security group | `nsg-` | `nsg-app-prod-eus-001` | |
| Public IP | `pip-` | `pip-agw-prod-eus-001` | Public IPs on NICs are denied by policy |
| Network interface | `nic-` | `nic-web-dev-eus-001` | |
| Virtual machine | `vm-` | `vm-web-dev-eus-001` | Windows computer name max 15 characters |
| Key Vault | `kv-` | `kv-webapp-dev-eus-001` | Max 24 characters |
| Log Analytics workspace | `log-` | `log-platform-prod-eus-001` | |
| Storage account | `st` (no hyphens) | `stwebappdeveus001` | 3 to 24 lowercase letters and digits, globally unique |
| Policy definition | `pol-` | `pol-require-tag-owner` | |
| Initiative | `init-` | `init-landing-zone-baseline` | |

## 4. Naming rules

- Lowercase only.
- No spaces or special characters. Use hyphens, except where a resource type does not allow them (for example storage accounts).
- Do not put secrets, personal data or customer names in resource names.
- Decide the name before creating the resource. Many resources cannot be renamed.
- If a name is taken (storage accounts, Key Vaults), increment the instance number. Do not change the pattern.

## 5. Required tags

| Tag | Required | Allowed values | Purpose | Enforced by |
|---|---|---|---|---|
| `owner` | Yes | An email address | Who to contact about the resource | Policy: Require a tag (Deny) |
| `environment` | Yes | `dev`, `test`, `prod` | Separates cost, risk and access | Policy: Require a tag (Deny) |
| `cost-center` | Yes | e.g. `training`, `it-ops` | Charges spend to a budget | Policy: Require a tag on resources and on resource groups (Deny); inherited by resources from the resource group (Modify) |

`cost-center` is set once on the resource group and inherited by the resources inside it.

## 6. Optional tags

| Tag | Values | Purpose |
|---|---|---|
| `workload` | e.g. `webapp` | Groups resources by application |
| `expires` | `YYYY-MM-DD` | Marks temporary lab resources for cleanup |
| `data-class` | `public`, `internal`, `confidential` | Drives security and logging requirements |

## 7. Allowed regions

`eastus`, `eastus2` (enforced by the Allowed locations policy, Deny).

## 8. Policy summary

| Policy | Effect | Parameters | Reason |
|---|---|---|---|
| Require a tag on resources (x3) | Deny | `owner`, `environment`, `cost-center` | Accountability and cost tracking |
| Require a tag on resource groups | Deny | `cost-center` | Makes sure the group has the tag that resources inherit |
| Allowed locations | Deny | `eastus`, `eastus2` | Data residency and spend control |
| Network interfaces should not have public IPs | Deny | none | Private by default |
| Secure transfer to storage accounts should be enabled | Audit | none | Require HTTPS for storage traffic |
| Inherit a tag from the resource group if missing (separate assignment) | Modify | `cost-center` | Keeps tags consistent without manual work |

## 9. Exceptions

Requests for exceptions need: resource, reason, owner, and an expiry date. Use a policy exemption with an expiry. Review exceptions monthly.

## 10. Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | October 20, 2026 | Initial standard |
| 1.1 | October 31, 2026 | Added Require a tag on resource groups for `cost-center` |
