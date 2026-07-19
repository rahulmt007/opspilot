# Phase 0: AWS account safety and GitHub OIDC

Phase 0 creates only the GitHub OIDC identity provider, a repository-and-environment-scoped IAM role, and its inline policy. It does not create EC2, networking, storage, or application resources.

## Safety gates

Complete these in the AWS console before bootstrapping OIDC:

1. Enable MFA for the root user and do not use root for routine work.
2. Confirm whether the account uses the Free or Paid plan and record its credit expiration date.
3. In **Billing and Cost Management -> Billing preferences**, enable Free Tier usage alerts and CloudWatch billing alerts.
4. Create a small monthly AWS Budget with actual and forecasted email notifications.
5. Select one region for the showcase. This repository defaults to `us-east-1`.
6. Record the current Bills page as the zero-resource baseline.

Budgets and billing data are delayed; they are notifications, not hard spending caps.

## Authenticate locally without access keys

AWS CLI 2.32 or later supports temporary console credentials:

```powershell
aws login --profile opspilot-bootstrap --region us-east-1
aws sts get-caller-identity --profile opspilot-bootstrap
```

Do not create or store long-lived AWS access keys for this project.

Install Terraform locally if it is not already available:

```powershell
winget install --id Hashicorp.Terraform --exact
terraform version
```

Export the browser session only into the PowerShell process that runs Terraform. This avoids long-lived keys and avoids depending on nested `credential_process` behavior in the Terraform AWS provider:

```powershell
$credentials = aws configure export-credentials --profile opspilot-bootstrap --format process | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $credentials.SessionToken
$env:AWS_REGION = "us-east-1"
$env:AWS_EC2_METADATA_DISABLED = "true"
```

Do not print these variables, pass them into a Docker command, or commit AWS profile files. Remove the variables or close the shell as soon as bootstrap work is complete.

## Bootstrap the OIDC role

If the AWS account does not already have the GitHub Actions OIDC provider:

```powershell
terraform -chdir=infra/bootstrap/oidc init
terraform -chdir=infra/bootstrap/oidc plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap/oidc apply bootstrap.tfplan
```

If `token.actions.githubusercontent.com` already exists as an account-wide provider, set:

```text
create_oidc_provider       = false
existing_oidc_provider_arn = "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
```

Review the plan before typing `yes`. Save the `aws_account_id` and `github_role_arn` outputs.

The trust policy requires both:

- audience: `sts.amazonaws.com`
- subject: `repo:rahulmt007/opspilot:environment:aws-showcase`

This repository was created before GitHub's July 15, 2026 immutable-subject rollout. If the repository is renamed, transferred, or opts into immutable OIDC subjects, update the exact subject in AWS before running the workflow.

The role cannot manage IAM, EKS, RDS, S3, Route 53, load balancers, or NAT Gateways. EC2 access is region-bound, and `RunInstances` is restricted to `t3.micro`.

## Configure the protected GitHub environment

After authenticating GitHub CLI, create the environment and set non-secret variables:

```powershell
gh api --method PUT repos/rahulmt007/opspilot/environments/aws-showcase
gh variable set AWS_REGION --repo rahulmt007/opspilot --env aws-showcase --body us-east-1
gh variable set AWS_ACCOUNT_ID --repo rahulmt007/opspilot --env aws-showcase --body <account-id>
gh variable set AWS_ROLE_ARN --repo rahulmt007/opspilot --env aws-showcase --body <role-arn>
```

In **Settings -> Environments -> aws-showcase**:

- allow deployments only from `main`;
- add required reviewers when the repository plan supports them;
- prevent self-review when another reviewer is available;
- never add AWS access keys as secrets.

## Verify without creating workload resources

Run **AWS plan** manually in GitHub Actions with a near-term ISO-8601 `expires_at` value. A successful run proves OIDC role assumption and Terraform planning only.

Phase 3 enables guarded plan/apply/destroy only after a versioned, encrypted S3 state bucket is pre-created and the OIDC role is granted access to its state and lock objects. See [the Phase 3 runbook](PHASE3_AWS_SHOWCASE.md).

## Cleanup

If the project is abandoned before Phase 3:

```powershell
terraform -chdir=infra/bootstrap/oidc destroy
aws logout --profile opspilot-bootstrap
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
```
