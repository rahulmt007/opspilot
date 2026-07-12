from pathlib import Path

from .runner import CommandResult, GuardedRunner


class Actions:
    def __init__(self, root: Path, execute: bool = False) -> None:
        self.root, self.runner = root, GuardedRunner(root, execute)

    def status(self) -> list[CommandResult]:
        return [self.runner.run(["git", "status", "--short"])]

    def plan(self) -> list[CommandResult]:
        return [
            self.runner.run(["docker", "compose", "config", "--quiet"]),
            self.runner.run(["kubectl", "apply", "--dry-run=client", "-f", "deploy/k8s"]),
            self.runner.run(["terraform", f"-chdir={self.root / 'infra/terraform'}", "validate"]),
        ]

    def deploy_local(self) -> list[CommandResult]:
        return [self.runner.run(["docker", "compose", "up", "--build", "-d"])]

    def deploy_k8s(self) -> list[CommandResult]:
        return [
            self.runner.run(["kind", "create", "cluster", "--name", "opspilot"]),
            self.runner.run(["docker", "build", "-t", "opspilot:local", "."]),
            self.runner.run(
                ["kind", "load", "docker-image", "opspilot:local", "--name", "opspilot"]
            ),
            self.runner.run(["kubectl", "apply", "-f", "deploy/k8s"]),
            self.runner.run(
                ["kubectl", "rollout", "status", "deployment/opspilot", "-n", "opspilot"]
            ),
        ]

    def aws_plan(self) -> list[CommandResult]:
        tf = f"-chdir={self.root / 'infra/terraform'}"
        return [
            self.runner.run(["terraform", tf, "init"]),
            self.runner.run(["terraform", tf, "plan"]),
        ]

    def aws_apply(self) -> list[CommandResult]:
        return [
            self.runner.run(
                ["terraform", f"-chdir={self.root / 'infra/terraform'}", "apply", "-auto-approve"],
                destructive=True,
            )
        ]

    def aws_destroy(self) -> list[CommandResult]:
        return [
            self.runner.run(
                [
                    "terraform",
                    f"-chdir={self.root / 'infra/terraform'}",
                    "destroy",
                    "-auto-approve",
                ],
                destructive=True,
            )
        ]

    def rollback(self) -> list[CommandResult]:
        return [
            self.runner.run(
                ["kubectl", "rollout", "undo", "deployment/opspilot", "-n", "opspilot"],
                destructive=True,
            )
        ]
