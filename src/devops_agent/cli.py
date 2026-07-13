from pathlib import Path
from typing import Annotated

import typer

from .actions import Actions

app = typer.Typer(help="Cost-guarded DevOps automation agent", no_args_is_help=True)
ROOT = Path(__file__).resolve().parents[2]


def show(results: list) -> None:
    failed = False
    for result in results:
        typer.echo(result.stdout)
        failed |= result.returncode != 0
    if failed:
        raise typer.Exit(1)


def _action(name: str, execute: bool) -> None:
    show(getattr(Actions(ROOT, execute), name)())


@app.command()
def status(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("status", execute)


@app.command()
def plan(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("plan", execute)


@app.command("deploy-local")
def deploy_local(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("deploy_local", execute)


@app.command("deploy-k8s")
def deploy_k8s(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("deploy_k8s", execute)


@app.command("aws-plan")
def aws_plan(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("aws_plan", execute)


@app.command("aws-apply")
def aws_apply(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("aws_apply", execute)


@app.command("aws-destroy")
def aws_destroy(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("aws_destroy", execute)


@app.command()
def rollback(execute: Annotated[bool, typer.Option("--execute")] = False) -> None:
    _action("rollback", execute)


@app.command()
def ask(prompt: str) -> None:
    from .llm import answer

    typer.echo(answer(prompt, ROOT))
