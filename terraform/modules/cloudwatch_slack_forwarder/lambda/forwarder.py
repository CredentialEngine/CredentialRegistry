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


def _format_k8s_event(log_event):
    """Try to extract a clean K8s event summary from a Fluent Bit-wrapped log line.

    Returns a dict with display fields, or None if not a K8s event."""
    try:
        outer = json.loads(log_event.get("message", ""))
        ev = outer.get("log_processed") or json.loads(outer.get("log", ""))
        obj = ev.get("involvedObject", {})
        if not obj:
            return None
        return {
            "reason": ev.get("reason", ""),
            "type": ev.get("type", ""),
            "namespace": obj.get("namespace", ""),
            "name": obj.get("name", ""),
            "kind": obj.get("kind", ""),
            "message": ev.get("message", ""),
            "component": ev.get("source", {}).get("component", ""),
            "timestamp": ev.get("lastTimestamp") or ev.get("firstTimestamp", ""),
        }
    except Exception:
        return None


def _format_es_log(log_event):
    """Try to extract a clean Elasticsearch application log summary.

    Returns a dict with display fields, or None if not an ES log."""
    try:
        outer = json.loads(log_event.get("message", ""))
        lp = outer.get("log_processed") or json.loads(outer.get("log", ""))
        if "elasticsearch.cluster.name" not in lp and "data_stream.dataset" not in lp:
            return None
        k8s = outer.get("kubernetes", {})
        return {
            "level": lp.get("log.level", "WARN"),
            "message": lp.get("message", ""),
            "logger": lp.get("log.logger", "").split(".")[-1],
            "node": lp.get("elasticsearch.node.name", ""),
            "cluster": lp.get("elasticsearch.cluster.name", ""),
            "dataset": lp.get("data_stream.dataset", ""),
            "event_code": lp.get("event.code", ""),
            "namespace": k8s.get("namespace_name", ""),
            "pod": k8s.get("pod_name", ""),
            "timestamp": lp.get("@timestamp", ""),
        }
    except Exception:
        return None


def _build_slack_payload(log_data, channel):
    """Build a Slack Block Kit message from decoded CloudWatch log data."""
    log_events = log_data.get("logEvents", [])
    events_to_show = log_events[:5]
    total = len(log_events)

    blocks = []

    for event in events_to_show:
        k8s = _format_k8s_event(event)
        es = _format_es_log(event) if not k8s else None

        if k8s and k8s["reason"]:
            icon = ":red_circle:" if k8s["type"] == "Warning" else ":large_blue_circle:"
            blocks.append({
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{icon}  K8s {k8s['type']}: {k8s['reason']}",
                },
            })
            blocks.append({
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Namespace:*\n`{k8s['namespace']}`"},
                    {"type": "mrkdwn", "text": f"*{k8s['kind']}:*\n`{k8s['name']}`"},
                    {"type": "mrkdwn", "text": f"*Component:*\n`{k8s['component']}`"},
                    {"type": "mrkdwn", "text": f"*Time:*\n`{k8s['timestamp']}`"},
                ],
            })
            blocks.append({
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*Message:*\n{k8s['message']}"},
            })
        elif es:
            icon = ":warning:" if es["level"] == "WARN" else ":red_circle:"
            blocks.append({
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{icon}  Elasticsearch {es['level']}: {es['event_code'] or es['dataset']}",
                },
            })
            blocks.append({
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Cluster:*\n`{es['cluster']}`"},
                    {"type": "mrkdwn", "text": f"*Node:*\n`{es['node']}`"},
                    {"type": "mrkdwn", "text": f"*Namespace:*\n`{es['namespace']}`"},
                    {"type": "mrkdwn", "text": f"*Time:*\n`{es['timestamp']}`"},
                ],
            })
            blocks.append({
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*Message:*\n{es['message'][:500]}"},
            })
        else:
            # Fallback: raw message, truncated
            message = event.get("message", "").strip()
            if len(message) > 2900:
                message = message[:2900] + "... (truncated)"
            blocks.append({
                "type": "header",
                "text": {"type": "plain_text", "text": "CloudWatch Log Alert"},
            })
            blocks.append({
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"```{message}```"},
            })

        blocks.append({"type": "divider"})

    if total > 5:
        blocks.append({
            "type": "context",
            "elements": [{"type": "mrkdwn", "text": f"Showing 5 of {total} log events in this batch."}],
        })

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
