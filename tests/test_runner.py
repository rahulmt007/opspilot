from pathlib import Path

import pytest

from devops_agent.runner import GuardedRunner


def test_dry_run_is_default(tmp_path: Path) -> None:
    assert GuardedRunner(tmp_path).run(["terraform", "version"]).dry_run


def test_rejects_unlisted_command(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="allow-listed"):
        GuardedRunner(tmp_path).run(["powershell", "dangerous.ps1"])
