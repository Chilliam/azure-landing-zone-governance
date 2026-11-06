# J1 Session 2: Build and Test the Landing Zone Guardrails

**Author:** William Crenshaw | **Date:** October 31 to November 1, 2026
**Scope:** `mg-lz-dev` (management group) | **Status:** Complete

## Objective

Turn the planned policy table into working guardrails: build a policy initiative, assign it to `mg-lz-dev`, add a separate tag-inheritance policy, then prove the guardrails block bad deployments and allow good ones.

## What I built

| Item | Detail |
|---|---|
| Initiative | `init-landing-zone-baseline`, defined at `mg-landingzones` |
| Initiative assignment | Assigned at `mg-lz-dev`, enforcement mode Default, custom non-compliance message |
| Modify policy | "Inherit a tag from the resource group if missing" (`cost-center`), assigned at `mg-lz-dev` with a system-assigned managed identity |
| Role | The Modify identity holds **Contributor** at `mg-lz-dev` (granted automatically at assignment; verified) |

### Policies in the initiative

| Policy | Effect | Parameters |
|---|---|---|
| Require a tag on resources (x3) | Deny | `owner`, `environment`, `cost-center` |
| Require a tag on resource groups | Deny | `cost-center` |
| Allowed locations | Deny | `eastus`, `eastus2` |
| Network interfaces should not have public IPs | Deny | none |
| Secure transfer to storage accounts should be enabled | Audit | none |

The initiative holds seven policy references, and with the separate Modify assignment the compliance page reports eight policies.

## Steps taken

1. **Created the initiative** (Policy > Definitions > + Initiative definition) with the initiative location set to `mg-landingzones`, so it can be assigned to both `mg-lz-dev` and `mg-lz-prod`.
2. **Added each policy**, adding "Require a tag on resources" once per tag with a unique reference ID and a fixed tag name value.
3. **Assigned the initiative** at `mg-lz-dev` with a non-compliance message pointing to the naming and tagging standard.
4. **Assigned the Modify policy separately** with a system-assigned managed identity.
5. **Checked the identity's role** in Access control (IAM) and from the CLI.
6. **Ran seven tests** from Cloud Shell in a new resource group (below).
7. **Checked Policy > Compliance** for the Audit result.

## Test results

| # | Test | Expected | Result |
|---|---|---|---|
| 1 | Create a resource group without `cost-center` | Denied | Denied by "Require a tag on resource groups" (`RequestDisallowedByPolicy`) |
| 2 | Create a resource group with all three tags | Succeeds | Succeeded |
| 3 | Create a storage account with no tags | Denied | Denied |
| 4 | Create a storage account in `westus` | Denied | Denied by Allowed locations |
| 5 | Create a NIC with a public IP | Denied | VNet and public IP created; NIC denied |
| 6 | Create a resource with `owner` and `environment` only | Succeeds with inherited `cost-center` | Succeeded; `cost-center: training` was added |
| 7 | Create a storage account with HTTPS-only turned off | Allowed but flagged | Created; compliance page showed 80% (4 of 5) with 1 non-compliant resource and policy |

The Modify policy also added `cost-center` to the VNet and public IP in test 5, which shows inheritance works across resource types.

## Problems I hit and how I fixed them

### 1. "This policy does not support remediation tasks" (Remediation tab)
- **What happened:** assigning "Inherit a tag from the resource group if missing" showed a warning that the policy doesn't support remediation, even though it's a Modify policy.
- **What I checked:** the Basics tab showed the correct policy, scope and version, and the Parameters tab showed only the tag name.
- **Outcome:** the cause isn't confirmed. The assignment was created anyway, and tests 5 and 6 showed it adding `cost-center` to new resources. New resources don't need a remediation task, but existing resources would need one from Policy > Remediation.
- **Lesson:** warnings in the portal don't always mean the assignment is broken. Verify behavior with a real test.

### 2. IAM showed different IDs from the assignment page
- **What happened:** the Contributor role in IAM showed an ID that didn't match the principal ID from `az policy assignment show`.
- **Cause:** managed identities have two IDs. IAM showed the client ID (`principalName` in the CLI output), and the assignment details show the object ID. The role had already been granted automatically when I created the assignment.
- **Lesson:** compare like with like (object ID versus client ID), and look at the role assignment's creation time before assuming a role is missing. Re-running `az role assignment create` for an existing role simply returns the existing one.

### 3. `SubscriptionNotFound` when creating a storage account
- **What happened:** resource groups were created fine, but every storage account command failed with `(SubscriptionNotFound) Subscription ... was not found`, even though the subscription was enabled and listed under `mg-lz-dev`.
- **Cause:** `Microsoft.Storage` showed `NotRegistered` on this subscription. A new subscription has to register each resource provider before first use.
- **Fix:**
  ```
  az provider show --namespace Microsoft.Storage --query registrationState -o tsv
  az provider register --namespace Microsoft.Storage --wait
  ```
- **Lesson:** an error that sounds like an access problem can be a missing resource provider registration. A policy denial looks different (`RequestDisallowedByPolicy`), so the error code tells you which layer is blocking you.

### 4. Cloud Shell sign-in problems (`MSAL token cache` and error 530035)
- **What happened:** `az account list --refresh` reported that the user didn't exist in the MSAL token cache. Running `az login` with a device code then failed in the browser with "You don't have access to this", error code **530035**, app "Microsoft Azure CLI".
- **Cause:** the saved Cloud Shell token had expired. The cause of 530035 isn't documented by Microsoft in anything I found; community reports point to sign-in policy conditions such as MFA setup, VPN or network. I did not need to fix it.
- **Fix:** I skipped `az login`, closed and reopened Cloud Shell from the portal, and `az account show` then returned the subscription.
- **Lesson:** Cloud Shell signs you in through the portal, so restarting it is faster than a device-code login. Keep the Correlation ID from any sign-in error so it can be looked up in the Entra sign-in logs.

### 5. Smaller issues
- **Pasted placeholders:** I pasted `<principalId>` literally into a command, and bash treated it as a file redirect (`No such file or directory`). Replace placeholders with real values.
- **Portal wording:** the field was labeled "Initiative location", not "Definition location".
- **Enforcement mode:** the assignment page offered **Enroll** as well as Default and Do not enforce. Only **Default (enforcement)** makes Deny policies block deployments.
- **"This policy has no parameters"** on the initiative assignment's Parameters tab is expected when values are set directly inside the initiative instead of through initiative parameters.
- **Scope selection:** selecting a management group in the scope panel doesn't apply until you click **Select**. Check that the Scope box shows the right group.

## Lessons learned

- Plan the policies first (table of policy, effect, parameters, reason), then build. Having the table made the portal work straightforward.
- Put the **non-compliance message** in the assignment. It appears in every denial and tells the person what to read next.
- Use **resource group tag enforcement plus Modify inheritance**: require `cost-center` on the group, and let resources inherit it. Azure applies Modify before Deny, so inherited tags satisfy the Require check.
- The built-in "Require a tag on resources" does not evaluate resource groups. That's why a separate resource group policy is needed.
- Test each policy with a resource that carries every *other* required tag, so a denial points to one policy.
- Use **Audit** before **Deny** when rolling out in a real environment, and keep Deny for rules you're sure of.
- Compliance data takes a while to appear (I saw 100% at first, then 80% after the scan). Use `az policy state trigger-scan` and wait.
- New subscriptions need resource providers registered (`Microsoft.Storage`, `Microsoft.Network`) before policy tests on those services.

## Gaps and next steps

- Both test storage accounts defaulted to `minimumTlsVersion: TLS1_0`. Add a policy requiring TLS 1.2 or higher.
- Add a diagnostic settings policy so logs go to Log Analytics.
- Move assignment to a pipeline with a what-if check (Session 4).
- Add budgets and the cost-by-tag view (Session 3).

## Evidence

Screenshots to keep in `/evidence` (redact the subscription ID, tenant ID and email address before publishing):

- `denied-resource-group.png` (test 1)
- `denied-storage-no-tags.png` (test 3)
- `denied-region.png` (test 4)
- `denied-nic-public-ip.png` (test 5)
- `inherited-tag.png` (test 6)
- `compliance-80-percent.png` and `compliance-noncompliant-policy.png` (test 7)

## Cleanup

The test resource group was deleted afterwards:

```
az group delete -n rg-policytest-dev-eus-001 --yes --no-wait
```
