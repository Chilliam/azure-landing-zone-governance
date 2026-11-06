# J1 Session 3: Budgets, Alerts and Cost-by-Tag

**Author:** William Crenshaw | **Date:** November 2, 2026
**Scope:** Azure subscription 1 (under `mg-lz-dev`) | **Status:** Complete

## Objective

Make spend visible and traceable: set a monthly budget with alerts, report cost by the `cost-center` tag, turn on tag inheritance for cost data, and create a permanent, correctly tagged resource group.

## What I built

| Item | Detail |
|---|---|
| Budget | `budget-landingzone-dev-monthly`, $25/month, subscription scope |
| Alerts | Actual 50%, 80%, 100% and Forecasted 100%, emailed to the owner |
| Saved view | `cost-by-tag` in Cost analysis, grouped by tag `cost-center` |
| Tag inheritance | Enabled at the subscription: "Use the subscription or resource group tag" |
| Permanent group | `rg-governance-dev-eus-001` with `owner`, `environment`, `cost-center` tags |

## Steps taken

1. **Created the budget** at subscription scope (Cost Management > Budgets > + Add) with a monthly reset and the four alert conditions.
2. **Built the cost-by-tag view** in Cost analysis: scope Azure subscription 1, Group by Tag > `cost-center`, saved as `cost-by-tag`.
3. **Enabled tag inheritance** at Settings > Manage subscription > Tag inheritance, and chose the subscription or resource group tag over the resource's own tag.
4. **Created `rg-governance-dev-eus-001`** with all three required tags, which the initiative accepts.
5. **Checked the result:** Cost analysis showed spend grouped under `training` and the $25 budget line.

## Design choices

- **$25 budget:** a lab subscription should cost close to nothing, so $25 is a tripwire. The 50% alert is an early warning, and the forecast alert catches a runaway resource before the month ends.
- **Alerts on actual and forecast:** actual alerts report what already happened, forecast alerts warn ahead of time.
- **Group tag wins:** `cost-center` is set once on the resource group, so inheritance uses the group's value and reports stay consistent.
- **Budgets alert, they don't stop spend.** An action group could shut things down, but I left that out for this lab.

## Problems and corrections

- **Menu path:** I first looked for tag inheritance under Settings > Configuration. At subscription scope it is under **Settings > Manage subscription > Tag inheritance** (Microsoft docs). Lesson: the path differs by scope, so check the docs.
- **Wrong blade:** the green hexagon **Cost Management** is the right one. "Cost Management + Billing" opened billing-account scope, and the scope panel needed the "Only show subscriptions selected in the global filter" box cleared before the subscription appeared.
- **Greyed Apply button:** the dialog's Apply was greyed out after the setting was already saved. Reopening the page showed the checkbox ticked.
- **Data lag:** cost and inherited tags take up to 24 hours to appear and only apply to the current month's usage.
- **Deleted resources keep their cost history.** The test group `rg-policytest-dev-eus-001` still appeared in charts after deletion.

### Local `az login` failed with AADSTS50076 (found Nov 3 while starting Session 4)
- **What happened:** `az login` on my PC returned `AADSTS50076: ... you must use multi-factor authentication`, then "No subscriptions found" for the account.
- **Cause:** the tenant requires MFA, and the default login doesn't send the MFA challenge. This is likely the same condition behind the 530035 sign-in error I saw in Cloud Shell during Session 2, though I did not confirm that.
- **Fix:** log in against the tenant directly, which triggers the MFA prompt:
  ```
  az login --tenant <tenant-id>
  ```
  The error output lists the exact command. `--use-device-code` is the fallback if the browser sign-in misbehaves.
- **Lesson:** AADSTS50076 means MFA is required. `az login --tenant` forces the interactive MFA challenge. Keep the Correlation ID from sign-in errors for the Entra sign-in logs, and redact the tenant ID before publishing.

## Lessons learned

- Tags make cost reporting work, which is why the initiative requires them and Modify fills them in.
- Set a budget before building anything, not after the first surprise bill.
- Tag inheritance for cost data and the Modify policy do different jobs: Modify changes the resource's tags, while inheritance only changes how cost records are labelled.

## Evidence

Keep in `/evidence` (redact subscription ID, tenant ID and email before publishing):

- `cost-by-tag.png` (saved view, `training` grouping, budget line)
- `budget.png` (alert conditions)
- `tag-inheritance.png` (setting enabled)
- `rg-governance-tags.png` (group with the three tags)

## Next

Session 4: rebuild the landing zone as code (Bicep or Terraform), including management groups, the initiative, assignments and the budget.
