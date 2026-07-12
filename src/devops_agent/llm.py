import json
import os
from pathlib import Path

from .actions import Actions

TOOLS = [
    {
        "type": "function",
        "name": "run_action",
        "description": "Run a safe action in dry-run mode.",
        "parameters": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "enum": [
                        "status",
                        "plan",
                        "deploy_local",
                        "deploy_k8s",
                        "aws_plan",
                        "rollback",
                    ],
                }
            },
            "required": ["name"],
            "additionalProperties": False,
        },
        "strict": True,
    }
]


def answer(prompt: str, root: Path) -> str:
    try:
        from openai import OpenAI
    except ImportError as exc:
        raise RuntimeError("Install the agent extra: pip install -e '.[agent]'") from exc
    if not os.getenv("OPENAI_API_KEY"):
        raise RuntimeError("OPENAI_API_KEY is required")
    client, model = OpenAI(), os.getenv("OPENAI_MODEL", "gpt-5.6-luna")
    response = client.responses.create(
        model=model,
        input=prompt,
        tools=TOOLS,
        instructions=(
            "You are OpsPilot. Prefer planning. Tools are dry-run only. "
            "Explain cost and destructive risk."
        ),
    )
    outputs = []
    for item in response.output:
        if item.type == "function_call" and item.name == "run_action":
            results = getattr(Actions(root), json.loads(item.arguments)["name"])()
            outputs.append(
                {
                    "type": "function_call_output",
                    "call_id": item.call_id,
                    "output": "\n".join(result.stdout for result in results),
                }
            )
    if outputs:
        response = client.responses.create(
            model=model, previous_response_id=response.id, input=outputs, tools=TOOLS
        )
    return response.output_text
