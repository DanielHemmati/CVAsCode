import json
import logging
import os
from pathlib import Path
from typing import Any

import boto3
from botocore.config import Config


LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)

RESUME_PATH = Path(__file__).with_name("index.md")
MAX_TOKENS = 250
TEMPERATURE = 0.2

BEDROCK_CLIENT = boto3.client(
    "bedrock-runtime",
    config=Config(
        retries={"total_max_attempts": 3, "mode": "adaptive"},
        connect_timeout=3,
        read_timeout=20,
    ),
)


def load_resume(path: Path = RESUME_PATH) -> str:
    """Load the packaged Markdown resume."""
    resume = path.read_text(encoding="utf-8").strip()
    if not resume:
        raise ValueError("The resume file is empty.")
    return resume


def build_prompt(resume: str) -> str:
    """Build a fixed prompt that callers cannot change."""
    return f"""Summarize the resume below for a hiring manager.

Requirements:
- Return only valid JSON with this shape: {{"summary":["point 1","point 2","point 3","point 4","point 5"]}}
- Return exactly five short points.
- Cover skills, experience, certifications, education, and selected projects.
- Use only facts from the resume.
- Do not invent achievements, dates, metrics, or technologies.
- Do not include Markdown or extra text outside the JSON object.

Resume:
{resume}
"""


def parse_summary(response: dict[str, Any]) -> list[str]:
    """Extract and validate five summary points from a Converse response."""
    content = response["output"]["message"]["content"]
    model_text = "".join(
        block["text"] for block in content if isinstance(block.get("text"), str)
    ).strip()

    if model_text.startswith("```") and model_text.endswith("```"):
        lines = model_text.splitlines()
        model_text = "\n".join(lines[1:-1]).strip()

    payload = json.loads(model_text)
    summary = payload.get("summary")

    if not isinstance(summary, list) or len(summary) != 5:
        raise ValueError("The model response must contain five summary points.")

    if any(not isinstance(point, str) or not point.strip() for point in summary):
        raise ValueError("Every summary point must be a non-empty string.")

    return [point.strip() for point in summary]


def response(status_code: int, payload: dict[str, Any]) -> dict[str, Any]:
    """Build an API Gateway payload version 2.0 response."""
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Return a server-controlled Bedrock summary of the packaged resume."""
    del context

    method = event.get("requestContext", {}).get("http", {}).get("method")
    if method != "GET":
        return response(405, {"message": "Method not allowed."})

    try:
        resume = load_resume()
        model_id = os.environ["BEDROCK_MODEL_ID"]
    except (OSError, ValueError, KeyError) as error:
        LOGGER.error(
            "summary_configuration_error",
            extra={"error_type": type(error).__name__},
        )
        return response(500, {"message": "Unable to create the summary."})

    try:
        bedrock_response = BEDROCK_CLIENT.converse(
            modelId=model_id,
            messages=[
                {
                    "role": "user",
                    "content": [{"text": build_prompt(resume)}],
                }
            ],
            inferenceConfig={
                "maxTokens": MAX_TOKENS,
                "temperature": TEMPERATURE,
            },
        )
    except Exception as error:
        LOGGER.warning(
            "bedrock_request_failed",
            extra={"error_type": type(error).__name__},
        )
        return response(502, {"message": "The summary service is unavailable."})

    try:
        summary = parse_summary(bedrock_response)
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        LOGGER.warning(
            "bedrock_response_invalid",
            extra={"error_type": type(error).__name__},
        )
        return response(502, {"message": "The summary service returned an invalid response."})

    return response(200, {"summary": summary})
