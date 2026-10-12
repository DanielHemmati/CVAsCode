# Terraform Drift Detection Plan

## Goal

Create `.github/workflows/drift-detection.yaml` to detect changes outside Terraform. Run it every 12 hours and allow a manual run.

Send one Telegram message after every run. The message must state whether Terraform found drift, found no drift, or failed to complete.

## Fixed Design

- Use Terraform `1.16.1`.
- Use the provider versions in each committed `.terraform.lock.hcl` file.
- Use the S3 remote backends in `terraform/live`.
- Run in GitHub Actions with the `production` environment.
- Authenticate to AWS through GitHub OIDC.
- Reuse the existing `github-actions-cvascode` role.
- Scan every tracked root that contains a `backend.tf` file.
- Scan roots one at a time to keep the output and state locks simple.
- Never run `terraform apply` in this workflow.
- Do not upload Terraform plans or plan text as public artifacts.
- Use the existing `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` secrets.

The main risk is CI drift. Secret exposure and state corruption are also in scope. The workflow is read-only for infrastructure, but Terraform needs read access to state and AWS resources.

## Workflow Trigger and Access

Add these triggers:

```yaml
on:
  schedule:
    - cron: "0 */12 * * *"
  workflow_dispatch: {}
```

The schedule runs at 00:00 and 12:00 UTC. GitHub runs scheduled workflows from the default branch.

Set these workflow controls:

- Use `ubuntu-24.04`.
- Set a 30-minute job timeout.
- Set one concurrency group for drift detection.
- Set `cancel-in-progress` to `false`.
- Grant `contents: read` and `id-token: write` to the job.
- Set the job environment to `production` for the current OIDC trust policy.
- Set `TF_IN_AUTOMATION=true` and `TF_INPUT=false`.
- Set the AWS Region to `us-east-1`.
- Pin third-party actions to full commit hashes, as the existing workflows do.

## Detection Steps

Implement one job with these steps:

1. Check out the default-branch commit.
2. Install Terraform `1.16.1` with the wrapper disabled.
3. Authenticate to AWS with the existing OIDC role.
4. Find tracked files that match `terraform/live/**/backend.tf`.
5. Run `terraform init -input=false -lockfile=readonly` in each root.
6. Run the drift command in each initialized root.
7. Collect one result for each root and continue until every root finishes.
8. Write a short result to the GitHub job summary.
9. Send one Telegram message with the combined result.
10. Fail the job after notification if any root has drift or an error.

Use this command for each root:

```bash
terraform -chdir="${stack_path}" plan \
  -detailed-exitcode \
  -input=false \
  -lock-timeout=5m \
  -no-color \
  -refresh-only
```

`-refresh-only` compares the remote resources with the current Terraform state. It does not propose configuration changes from the repository.

Interpret the exit codes as follows:

- Exit code `0`: No drift.
- Exit code `2`: Drift found.
- Any other exit code: Detection error.

Do not use `set -e` around the plan command. Capture its exit code so that code `2` does not stop the scan.

## Result Handling

Store only a short status for each root. Do not print or upload the full plan because it can contain resource data.

Use these final states:

- `NO_DRIFT` when every root returns exit code `0`.
- `DRIFT_FOUND` when one or more roots return exit code `2` and none return an error.
- `ERROR` when initialization or planning fails for any root.

List the affected root names in the job summary and Telegram message. Include the repository, run number, commit SHA, UTC time, and workflow URL.

Escape all repository data before sending Telegram HTML. Pass the Telegram token and chat ID through step environment variables, and never print them.

The notification step must use `if: always()`. A final step must return a nonzero exit code for `DRIFT_FOUND` or `ERROR` after the notification finishes.

Do not add this workflow to `.github/workflows/telegram-notifications.yaml`. The drift workflow sends its own result, so adding it there would send two messages.

## Failure Rules

- If no Terraform roots exist, report `ERROR` and fail the workflow.
- If one root fails to initialize, record the error and continue with the other roots.
- If Telegram secrets are absent, emit a GitHub error and fail the workflow.
- If Telegram rejects the request, fail the workflow after preserving the drift result in the job summary.
- If Terraform finds drift, do not apply or refresh the state.

## Validation

Run these local checks before merge:

```bash
actionlint .github/workflows/drift-detection.yaml
yamllint .github/workflows/drift-detection.yaml
```

Run the workflow manually from `main`. Make sure that all live roots initialize and that Telegram reports `NO_DRIFT` for a clean account.

For a safe drift test, change a reversible attribute on one noncritical AWS resource outside Terraform. Run the workflow and make sure that it reports `DRIFT_FOUND` without applying a change.

Restore the resource through the normal reviewed Terraform plan and apply workflow. Run drift detection again and make sure that it reports `NO_DRIFT`.

## Tradeoffs

The sequential scan takes longer than a matrix scan, but it produces one simple combined result. The `-refresh-only` plan targets changes made outside Terraform, but it does not detect unapplied repository configuration.

The current OIDC role has broad access. This plan reuses it for the smallest workflow change, but a later change can add a dedicated read-only drift role.

## Rollback

Delete `.github/workflows/drift-detection.yaml` to stop future runs. This change does not modify infrastructure or Terraform state, so no Terraform rollback is required.
