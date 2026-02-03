"""CloudWatch Logs to Slack forwarder.

Receives CloudWatch log events via subscription filter, formats them
using Slack Block Kit, and posts to a Slack incoming webhook.
The webhook URL is fetched from SSM Parameter Store and cached for the
lifetime of the Lambda execution environment.
"""

import base64
import gzip
import json
import os
import urllib.request

import boto3

# Cached across invocations within the same execution environment
_webhook_url = None


def _get_webhook_url():
    global _webhook_url
    if _webhook_url is None:
        ssm = boto3.client("ssm")
        param = ssm.get_parameter(
            Name=os.environ["SSM_WEBHOOK_PARAM"],
            WithDecryption=True,
        )
        _webhook_url = param["Parameter"]["Value"]
    return _webhook_url


def _build_slack_payload(log_data, channel):
    """Build a Slack Block Kit message from decoded CloudWatch log data."""
    log_group = log_data.get("logGroup", "unknown")
    log_stream = log_data.get("logStream", "unknown")
    log_events = log_data.get("logEvents", [])

    # Limit to 5 events per message to stay within Slack limits
    events_to_show = log_events[:5]
    total = len(log_events)

    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "CloudWatch Log Alert",
            },
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Log Group:*\n`{log_group}`"},
                {"type": "mrkdwn", "text": f"*Log Stream:*\n`{log_stream}`"},
            ],
        },
        {"type": "divider"},
    ]

    for event in events_to_show:
        message = event.get("message", "").strip()
        # Truncate long messages to avoid Slack block limits (3000 chars)
        if len(message) > 2900:
            message = message[:2900] + "... (truncated)"
        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"```{message}```"},
            }
        )

    if total > 5:
        blocks.append(
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Showing 5 of {total} log events in this batch.",
                    }
                ],
            }
        )

    return {"channel": channel, "blocks": blocks}


def handler(event, context):
    """Lambda entry point for CloudWatch Logs subscription filter events."""
    compressed = base64.b64decode(event["awslogs"]["data"])
    log_data = json.loads(gzip.decompress(compressed))

    # Control messages (e.g. from subscription filter test) are not real logs
    if log_data.get("messageType") == "CONTROL_MESSAGE":
        print("Received control message, skipping.")
        return {"statusCode": 200, "body": "control message"}

    channel = os.environ.get("SLACK_CHANNEL", "#alerts")
    webhook_url = _get_webhook_url()

    payload = _build_slack_payload(log_data, channel)
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        print(f"Slack response: {resp.status} {resp.read().decode()}")

    return {"statusCode": 200, "body": "ok"}
