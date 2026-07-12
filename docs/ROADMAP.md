# Phased implementation plan

## Phase 0 — account safety (before AWS)

- Create or select a sandbox AWS account; enable MFA and billing alerts.
- Determine new-versus-legacy Free Tier eligibility and choose one region.
- Create a GitHub OIDC role with repository and environment conditions.
- Configure a protected `aws-showcase` GitHub Environment.
- Capture a zero-resource billing baseline.

Exit: CI can assume only the scoped role, and the operator understands that credits are finite.

## Phase 1 — application and local platform (scaffolded)

- FastAPI health/readiness/metrics endpoints and tests.
- Multi-stage, non-root Docker image.
- Docker Compose with Prometheus and Grafana.
- `kind` manifests with probes, limits, security context, and rolling updates.

Exit: local Compose works and Kubernetes smoke tests pass.

## Phase 2 — delivery and supply-chain security (scaffolded)

- GitHub Actions for lint, tests, image build, Trivy, Checkov, and kind smoke test.
- Jenkinsfile retained as an interview artifact; GitHub Actions is the no-controller default.
- Add image publishing with immutable SHA tags, SBOM generation, and keyless signing.
- Pin third-party actions by commit SHA before production use.

Exit: a pull request produces repeatable test and scan evidence.

## Phase 3 — guarded AWS showcase (foundation scaffolded)

- Review Terraform, current prices, AMI architecture, and instance eligibility.
- Add remote state only if needed, using a pre-created low-cost backend.
- Publish image to GHCR and deploy a SHA/digest rather than `latest`.
- Verify health, save evidence, then destroy within the TTL window.

Exit: manual plan/apply/destroy workflow succeeds with no long-lived credentials.

## Phase 4 — agent maturity

- Persist structured action/audit records in SQLite locally.
- Add pre/postconditions, retry classification, and health-based automatic rollback.
- Add policy-as-code (OPA/Conftest) for forbidden costly resources and public ingress.
- Add cost estimation (Infracost where its free offering fits) and plan summarization.
- Build a small web UI showing plan, approvals, execution, metrics, and cost estimate.

Exit: every mutation has intent, plan, approval, execution result, and verification evidence.

## Phase 5 — portfolio polish

- Record a 90-second demo: prompt → dry run → CI → ephemeral deploy → health dashboard → rollback → destroy.
- Add architecture and threat-model diagrams, screenshots, CI badge, and a short postmortem.
- Publish measurable claims only: test count, scan results, deploy time, rollback time, and actual demo cost.

Suggested LinkedIn framing: “Built OpsPilot, a cost-guarded Python DevOps agent that turns approved intents into Terraform/Docker/Kubernetes workflows, validates supply-chain security in CI, verifies health, rolls back, and destroys ephemeral AWS infrastructure.”
