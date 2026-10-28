# Terraform infrastructure release strategy and calendar

This guide covers **Terraform IaC releases only**. It does not describe application-image promotion.

## Release policy

Integrate small reviewed infrastructure changes into `main`. Select an immutable tested commit/module version for a controlled infrastructure release. A release record should include:

- Release identifier, exact commit and affected environment(s).
- Resource impact, cost/capacity implications and planned destructions.
- Terraform/provider/module versions and validation evidence.
- Fresh environment-specific plan, checksum and workflow/run reference.
- Required approvals, deployment window, owner and support coverage.
- Verification steps, recovery options and actual result.

Never reuse a lower-environment plan or state in production. Re-plan if the selected configuration or infrastructure state changes materially before apply.

## Current implementation versus operating target

The repository implements manual dev saved-plan deployment and manual plan-only execution for all four environments. The complete staging/production saved-plan apply and release-calendar automation is **not implemented**. The process below is the target operating model.

The current dev run uses its `main` revision. Releasing an older tested commit later requires an explicitly designed release-ref workflow; tagging a commit alone does not make the existing workflow deploy it.

## Illustrative monthly calendar

| Timing | Activity | Responsible participants |
|---|---|---|
| Throughout month | Small PRs, configuration validation and development verification | Developers, platform engineer, reviewers |
| Five business days before window | Select candidate commit and confirm infrastructure scope | Release manager, platform lead |
| Four to two business days before | Verify selected changes in test/staging with fresh plans | Platform, QA, security and service owners |
| One business day before | Go/no-go: plan, risks, recovery, support readiness and change record | Release manager and authorized approvers |
| Agreed month-end staffed window | Generate/review final production plan, approve and apply that plan | Platform operator, independent approver |
| Following business day | Review health, drift/incident findings and follow-up actions | Operations and platform teams |

This is an example calendar, not a Rogers schedule. Choose a staffed low-impact window; avoid critical onboarding, store and enterprise service periods. Defer an unready release rather than deploying solely to meet the date.

## Approval decisions

1. **PR review:** Is the infrastructure change correct and adequately validated?
2. **Plan review:** Does this exact environment plan reflect the authorized impact?
3. **Release approval:** Is it appropriate to execute now, with support and recovery ready?
4. **Post-apply acceptance:** Did the intended resources and controls reach the verified state?

These decisions are distinct. The existing main ruleset's required review count is zero; independent PR approval is a target policy. The existing dev workflow references `dev-apply`, but required reviewers must be configured in environment settings.

## Infrastructure recovery

Terraform has no universal transactional undo. A code revert alone does not restore deployed infrastructure.

1. Stop further environment progression and preserve logs, the plan and state history.
2. Inspect which resource operations completed and compare actual infrastructure with state.
3. Decide whether to fix forward or revert compatible configuration.
4. Generate a new recovery plan against current state.
5. Review destructive impact and obtain the required approval.
6. Apply that exact recovery plan and verify resources and dependent services.

Use database snapshots/restore procedures for data recovery when required. Never automatically replace a newer Terraform state with an older object as a routine rollback. State recovery is a separate, controlled investigation. Account for resources already deleted or replaced.

## Emergency change

Use a focused fix branch, expedited review, targeted validation and recorded emergency approval. When unreleased changes exist on main, prepare the fix from the appropriate released baseline and reconcile it back to main. Generate fresh plans for every affected environment. Complete post-change verification and retrospective review.

## Release-manager presentation answer

“We integrate Terraform changes through short-lived branches and required checks. Dev uses a saved plan with a separate apply decision. Our target release process selects a tested immutable infrastructure revision and creates a fresh plan for each environment. Production changes execute in a staffed release window after plan and release approval. If a change fails, we inspect actual state and choose an approved recovery plan rather than assuming Terraform can automatically undo it.”
