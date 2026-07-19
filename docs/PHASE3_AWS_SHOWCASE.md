# Phase 3: guarded AWS showcase

Phase 3 deploys the already-tested, signed OpsPilot image to one short-lived EC2
instance. It is intentionally manual and time-boxed: the GitHub `aws-showcase`
environment must approve any `apply` or `destroy` run.

## One-time remote state bootstrap

Terraform state is stored in a pre-created S3 bucket with versioning, encryption,
public-access blocking, and native S3 lock files. The showcase OIDC role is allowed
to read and update only the state object and its `.tflock` object; it cannot create
or delete the bucket.

Create the bucket with the short-lived local bootstrap session, using a globally
unique name:

```powershell
$bucket = "opspilot-tfstate-<aws-account-id>"
$region = "us-east-1"

aws s3api create-bucket --bucket $bucket --region $region --profile opspilot-bootstrap
aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled --profile opspilot-bootstrap
aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --profile opspilot-bootstrap
aws s3api put-bucket-encryption --bucket $bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile opspilot-bootstrap
```

Then re-run the OIDC bootstrap plan and apply with:

```powershell
terraform -chdir=infra/bootstrap/oidc plan -var="terraform_state_bucket=$bucket" -out=oidc.tfplan
terraform -chdir=infra/bootstrap/oidc apply oidc.tfplan
```

Review the IAM policy diff carefully. This adds state-object access only; it does
not grant S3 bucket administration.

Set the protected environment variable once:

```powershell
gh variable set TF_STATE_BUCKET --repo rahulmt007/opspilot --env aws-showcase --body $bucket
```

## Running the workflow

Use the `AWS showcase` workflow manually from `main` with:

- `action=plan` to validate the configuration without creating workload resources;
- `action=apply` to create the ephemeral showcase after environment approval;
- `action=destroy` immediately after the demo to remove the workload.

For `image_digest`, use the digest from the verified GHCR image, for example:

```text
sha256:53c27eec2fbf78c17be2094646555ce7fb89020fbe1e94b2dbf967f0eb2c2c47
```

Use a near-term UTC `expires_at` value. The EC2 instance receives the digest-based
image reference through user data, exposes only port 8000 by default, and uses an
IMDSv2-required, encrypted root volume.

## Recovery and cleanup

Terraform state is the cleanup authority. If health verification fails, inspect the
workflow output and run the same workflow with `action=destroy`. If a lock remains
after a confirmed failed run, inspect the state bucket before considering a force
unlock. Never delete the state bucket while the showcase resources still exist.
