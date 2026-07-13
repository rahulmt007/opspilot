from __future__ import annotations

import os
import shlex
import subprocess
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CommandResult:
    command: tuple[str, ...]
    returncode: int
    stdout: str
    dry_run: bool


class GuardedRunner:
    """Executes only predeclared argv commands; shell interpretation is never enabled."""

    def __init__(self, root: Path, execute: bool = False) -> None:
        self.root = root.resolve()
        self.execute = execute

    def run(self, command: list[str], *, destructive: bool = False) -> CommandResult:
        if not command or command[0] not in {"docker", "kubectl", "terraform", "kind", "git"}:
            raise ValueError("command is not allow-listed")
        if not self.execute:
            return CommandResult(tuple(command), 0, f"DRY RUN: {shlex.join(command)}", True)
        if destructive and os.getenv("OPSPILOT_APPROVED", "").lower() != "true":
            answer = input(f"Approve destructive command '{shlex.join(command)}'? [y/N] ")
            if answer.lower() != "y":
                return CommandResult(tuple(command), 2, "Denied by approval gate", False)
        completed = subprocess.run(  # noqa: S603 - argv is fixed by allow-listed actions
            command,
            cwd=self.root,
            check=False,
            capture_output=True,
            text=True,
            timeout=900,
        )
        output = "\n".join(part for part in (completed.stdout, completed.stderr) if part).strip()
        return CommandResult(tuple(command), completed.returncode, output, False)
