from __future__ import annotations

from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import io
import json
import os
from queue import Empty, Queue
import subprocess
import sys
from threading import Thread
import zipfile

import boto3
import pytest

from main import process_batches


pytestmark = pytest.mark.integration
requires_localstack = pytest.mark.skipif(
    not os.getenv("AWS_ENDPOINT_URL"),
    reason="AWS_ENDPOINT_URL is not configured",
)


def create_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=os.environ["AWS_ENDPOINT_URL"],
        region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "test"),
    )


def empty_bucket(client, bucket_name: str) -> None:
    paginator = client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket_name):
        contents = page.get("Contents", [])
        if contents:
            client.delete_objects(
                Bucket=bucket_name,
                Delete={"Objects": [{"Key": item["Key"]} for item in contents]},
            )


def ensure_clean_bucket(client, bucket_name: str) -> None:
    existing_buckets = {bucket["Name"] for bucket in client.list_buckets().get("Buckets", [])}
    if bucket_name in existing_buckets:
        empty_bucket(client, bucket_name)
    else:
        client.create_bucket(Bucket=bucket_name)


def delete_bucket(client, bucket_name: str) -> None:
    empty_bucket(client, bucket_name)
    client.delete_bucket(Bucket=bucket_name)


def seed_source_bucket(client, bucket_name: str, *, total_graphs: int) -> dict[str, bytes]:
    graph_bodies = {
        f"graphs/graph-{index:03d}.json": f'{{"graph": {index}}}'.encode()
        for index in range(1, total_graphs + 1)
    }
    for key, body in graph_bodies.items():
        client.put_object(Bucket=bucket_name, Key=key, Body=body)

    client.put_object(Bucket=bucket_name, Key="graphs/ignore.txt", Body=b"ignore")
    return graph_bodies


def build_batch_key(destination_prefix: str, batch_number: int) -> str:
    cleaned_prefix = destination_prefix.strip("/")
    filename = f"batch-{batch_number:05d}.zip"
    return f"{cleaned_prefix}/{filename}" if cleaned_prefix else filename


def assert_uploaded_batches(
    client,
    *,
    destination_bucket: str,
    destination_prefix: str,
    expected_batch_sizes: list[int],
    graph_bodies: dict[str, bytes],
) -> None:
    next_graph_index = 1

    for batch_number, expected_count in enumerate(expected_batch_sizes, start=1):
        zip_bytes = client.get_object(
            Bucket=destination_bucket,
            Key=build_batch_key(destination_prefix, batch_number),
        )["Body"].read()

        start = next_graph_index
        end = start + expected_count - 1
        expected_names = [f"graph-{index:03d}.json" for index in range(start, end + 1)]

        with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
            assert sorted(archive.namelist()) == expected_names
            for index in range(start, end + 1):
                assert archive.read(f"graph-{index:03d}.json") == graph_bodies[
                    f"graphs/graph-{index:03d}.json"
                ]

        next_graph_index = end + 1


@contextmanager
def webhook_server(status_code: int = 204):
    received: Queue[dict[str, object]] = Queue()

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            content_length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(content_length)
            received.put(
                {
                    "path": self.path,
                    "headers": dict(self.headers),
                    "body": body,
                }
            )
            self.send_response(status_code)
            self.end_headers()

        def log_message(self, format: str, *args: object) -> None:
            return

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()

    host, port = server.server_address
    try:
        yield f"http://{host}:{port}/webhook", received
    finally:
        server.shutdown()
        thread.join(timeout=5)
        server.server_close()


@requires_localstack
def test_end_to_end_with_localstack() -> None:
    client = create_s3_client()
    source_bucket = "source-graphs-service"
    destination_bucket = "dest-archives-service"

    ensure_clean_bucket(client, source_bucket)
    ensure_clean_bucket(client, destination_bucket)

    try:
        graph_bodies = seed_source_bucket(client, source_bucket, total_graphs=50)

        results = process_batches(
            client,
            source_bucket=source_bucket,
            source_prefix="graphs/",
            destination_bucket=destination_bucket,
            destination_prefix="zips",
            max_uncompressed_zip_size_bytes=150,
            max_workers=4,
            read_chunk_size=1024,
            part_size=5 * 1024 * 1024,
        )

        assert [result.destination_key for result in results] == [
            "zips/batch-00001.zip",
            "zips/batch-00002.zip",
            "zips/batch-00003.zip",
            "zips/batch-00004.zip",
            "zips/batch-00005.zip",
        ]
        assert_uploaded_batches(
            client,
            destination_bucket=destination_bucket,
            destination_prefix="zips",
            expected_batch_sizes=[12, 11, 11, 11, 5],
            graph_bodies=graph_bodies,
        )
    finally:
        delete_bucket(client, source_bucket)
        delete_bucket(client, destination_bucket)


@requires_localstack
def test_cli_sends_completion_webhook_after_uploading_batches() -> None:
    client = create_s3_client()
    source_bucket = "source-graphs-webhook"
    destination_bucket = "dest-archives-webhook"

    ensure_clean_bucket(client, source_bucket)
    ensure_clean_bucket(client, destination_bucket)

    try:
        graph_bodies = seed_source_bucket(client, source_bucket, total_graphs=12)

        with webhook_server() as (webhook_url, received):
            completed = subprocess.run(
                [
                    sys.executable,
                    "main.py",
                    "--source-bucket",
                    source_bucket,
                    "--source-prefix",
                    "graphs/",
                    "--destination-bucket",
                    destination_bucket,
                    "--destination-prefix",
                    "zips",
                    "--max-uncompressed-zip-size-bytes",
                    "150",
                    "--batch-size",
                    "100",
                    "--max-workers",
                    "2",
                    "--read-chunk-size",
                    "1024",
                    "--part-size",
                    str(5 * 1024 * 1024),
                ],
                env={
                    **os.environ,
                    "WEBHOOK_URL": webhook_url,
                    "ENVIRONMENT": "integration",
                },
                capture_output=True,
                text=True,
                check=False,
            )

            assert completed.returncode == 0, (
                f"stdout:\n{completed.stdout}\n\nstderr:\n{completed.stderr}"
            )

            manifest = json.loads(completed.stdout.splitlines()[0])
            assert manifest["batch_count"] == 1
            assert manifest["total_files"] == 12
            assert manifest["total_input_bytes"] > 0
            assert manifest["zip_files"] == ["zips/batch-00001.zip"]
            assert manifest["zip_size_bytes"] > 0

            request_data = received.get(timeout=5)
            headers = request_data["headers"]
            body = json.loads(request_data["body"])
            text = body["text"]

            assert request_data["path"] == "/webhook"
            assert headers["Content-Type"] == "application/json"
            assert text.startswith(":white_check_mark: *CE Registry ZIP bundle succeeded*")
            assert "(integration)" in text
            assert ">*Files:* 12" in text
            assert f">*Uploaded:* `s3://{destination_bucket}/zips/batch-00001.zip`" in text
            assert ">*ZIP size:* " in text
            assert ">*Duration:* " in text

            with pytest.raises(Empty):
                received.get_nowait()

        assert_uploaded_batches(
            client,
            destination_bucket=destination_bucket,
            destination_prefix="zips",
            expected_batch_sizes=[12],
            graph_bodies=graph_bodies,
        )
    finally:
        delete_bucket(client, source_bucket)
        delete_bucket(client, destination_bucket)
