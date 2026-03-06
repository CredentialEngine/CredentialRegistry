from __future__ import annotations

import argparse
from concurrent.futures import FIRST_COMPLETED, Future, ThreadPoolExecutor, wait
from contextlib import closing
from dataclasses import dataclass
import io
import json
import os
from pathlib import Path
import sys
import time
from typing import Any, Iterable
from urllib import request
import zipfile

import boto3

DEFAULT_TIMEOUT_SECONDS = 30


@dataclass(slots=True)
class BatchResult:
    batch_number: int
    object_count: int
    destination_key: str
    zip_size_bytes: int


@dataclass(slots=True)
class SourceObject:
    key: str
    size_bytes: int


class S3UploadWriter(io.RawIOBase):
    def __init__(
        self,
        client: Any,
        bucket: str,
        key: str,
        *,
        part_size: int = 8 * 1024 * 1024,
        multipart_threshold: int | None = None,
        content_type: str = "application/zip",
    ) -> None:
        if part_size < 5 * 1024 * 1024:
            raise ValueError("part_size must be at least 5 MiB for S3 multipart uploads")

        self._client = client
        self._bucket = bucket
        self._key = key
        self._part_size = part_size
        self._multipart_threshold = multipart_threshold or part_size
        self._content_type = content_type

        self._buffer = bytearray()
        self._upload_id: str | None = None
        self._parts: list[dict[str, Any]] = []
        self._part_number = 1
        self._bytes_written = 0
        self._closed = False
        self._aborted = False

    def __enter__(self) -> S3UploadWriter:
        return self

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> bool:
        if exc_type is None:
            self.close()
        else:
            self.discard()
        return False

    def writable(self) -> bool:
        return True

    @property
    def bytes_written(self) -> int:
        return self._bytes_written

    @property
    def closed(self) -> bool:
        return self._closed

    def write(self, b: bytes | bytearray) -> int:
        if self._closed:
            raise ValueError("I/O operation on closed writer")

        if not b:
            return 0

        self._buffer.extend(b)
        self._bytes_written += len(b)

        if self._upload_id is None and len(self._buffer) >= self._multipart_threshold:
            self._start_multipart_upload()

        if self._upload_id is not None:
            self._flush_full_parts()

        return len(b)

    def close(self) -> None:
        if self._closed:
            return

        try:
            if self._upload_id is None:
                self._client.put_object(
                    Bucket=self._bucket,
                    Key=self._key,
                    Body=bytes(self._buffer),
                    ContentType=self._content_type,
                )
                self._buffer.clear()
            else:
                if self._buffer:
                    self._upload_part(bytes(self._buffer))
                    self._buffer.clear()

                self._client.complete_multipart_upload(
                    Bucket=self._bucket,
                    Key=self._key,
                    UploadId=self._upload_id,
                    MultipartUpload={"Parts": self._parts},
                )
        except Exception:
            self.discard()
            raise
        finally:
            self._closed = True
            super().close()

    def discard(self) -> None:
        if self._closed:
            return

        self._buffer.clear()

        if self._upload_id is not None and not self._aborted:
            self._client.abort_multipart_upload(
                Bucket=self._bucket,
                Key=self._key,
                UploadId=self._upload_id,
            )
            self._aborted = True

        self._closed = True
        super().close()

    def _start_multipart_upload(self) -> None:
        response = self._client.create_multipart_upload(
            Bucket=self._bucket,
            Key=self._key,
            ContentType=self._content_type,
        )
        self._upload_id = response["UploadId"]

    def _flush_full_parts(self) -> None:
        while len(self._buffer) >= self._part_size:
            chunk = bytes(self._buffer[: self._part_size])
            del self._buffer[: self._part_size]
            self._upload_part(chunk)

    def _upload_part(self, chunk: bytes) -> None:
        response = self._client.upload_part(
            Bucket=self._bucket,
            Key=self._key,
            UploadId=self._upload_id,
            PartNumber=self._part_number,
            Body=chunk,
        )
        self._parts.append(
            {
                "ETag": response["ETag"],
                "PartNumber": self._part_number,
            }
        )
        self._part_number += 1


def list_json_keys(
    client: Any,
    bucket: str,
    prefix: str = "",
    limit: int | None = None,
) -> list[SourceObject]:
    if limit is not None and limit <= 0:
        raise ValueError("limit must be greater than zero")

    normalized_prefix = prefix.strip("/")
    listing_prefix = f"{normalized_prefix}/" if normalized_prefix else ""

    paginator = client.get_paginator("list_objects_v2")
    keys: list[SourceObject] = []

    for page in paginator.paginate(Bucket=bucket, Prefix=listing_prefix):
        for item in page.get("Contents", []):
            key = item["Key"]
            if not key.endswith(".json"):
                continue

            keys.append(SourceObject(key=key, size_bytes=item["Size"]))
            if limit is not None and len(keys) == limit:
                return keys

    keys.sort(key=lambda item: item.key)
    return keys


def chunked_by_estimated_size(
    items: list[SourceObject],
    *,
    max_uncompressed_zip_size_bytes: int,
    max_batch_size: int | None = None,
) -> Iterable[list[SourceObject]]:
    if max_uncompressed_zip_size_bytes <= 0:
        raise ValueError("max_uncompressed_zip_size_bytes must be greater than zero")
    if max_batch_size is not None and max_batch_size <= 0:
        raise ValueError("max_batch_size must be greater than zero")

    batch: list[SourceObject] = []
    batch_size_bytes = 0

    for item in items:
        would_exceed_size = (
            batch and batch_size_bytes + item.size_bytes > max_uncompressed_zip_size_bytes
        )
        would_exceed_count = max_batch_size is not None and len(batch) >= max_batch_size

        if would_exceed_size or would_exceed_count:
            yield batch
            batch = []
            batch_size_bytes = 0

        batch.append(item)
        batch_size_bytes += item.size_bytes

    if batch:
        yield batch


def build_destination_key(destination_prefix: str, batch_number: int) -> str:
    cleaned = destination_prefix.strip("/")
    filename = f"batch-{batch_number:05d}.zip"
    return f"{cleaned}/{filename}" if cleaned else filename


def stream_objects_to_zip(
    client: Any,
    *,
    source_bucket: str,
    source_prefix: str,
    destination_bucket: str,
    destination_key: str,
    object_keys: list[str],
    batch_number: int,
    read_chunk_size: int = 1024 * 1024,
    part_size: int = 8 * 1024 * 1024,
) -> BatchResult:
    if read_chunk_size <= 0:
        raise ValueError("read_chunk_size must be greater than zero")

    normalized_prefix = source_prefix.strip("/")
    prefix_with_slash = f"{normalized_prefix}/" if normalized_prefix else ""

    with S3UploadWriter(
        client,
        destination_bucket,
        destination_key,
        part_size=part_size,
    ) as writer:
        with zipfile.ZipFile(
            writer,
            mode="w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=6,
        ) as archive:
            for key in object_keys:
                arcname = key
                if prefix_with_slash and key.startswith(prefix_with_slash):
                    arcname = key[len(prefix_with_slash) :]

                response = client.get_object(Bucket=source_bucket, Key=key)
                with (
                    closing(response["Body"]) as body,
                    archive.open(arcname, mode="w") as archive_entry,
                ):
                    while chunk := body.read(read_chunk_size):
                        archive_entry.write(chunk)

    return BatchResult(
        batch_number=batch_number,
        object_count=len(object_keys),
        destination_key=destination_key,
        zip_size_bytes=writer.bytes_written,
    )


def process_batches(
    client: Any,
    *,
    source_bucket: str,
    source_prefix: str,
    destination_bucket: str,
    destination_prefix: str,
    max_uncompressed_zip_size_bytes: int,
    max_workers: int,
    source_objects: list[SourceObject] | None = None,
    max_batch_size: int | None = None,
    read_chunk_size: int = 1024 * 1024,
    part_size: int = 8 * 1024 * 1024,
) -> list[BatchResult]:
    source_objects = source_objects or list_json_keys(client, source_bucket, source_prefix)
    if not source_objects:
        return []

    results: list[BatchResult] = []
    batch_iter = enumerate(
        chunked_by_estimated_size(
            source_objects,
            max_uncompressed_zip_size_bytes=max_uncompressed_zip_size_bytes,
            max_batch_size=max_batch_size,
        ),
        start=1,
    )

    def submit_batch(
        executor: ThreadPoolExecutor,
        batch_number: int,
        batch_objects: list[SourceObject],
    ) -> Future[BatchResult]:
        destination_key = build_destination_key(destination_prefix, batch_number)
        return executor.submit(
            stream_objects_to_zip,
            client,
            source_bucket=source_bucket,
            source_prefix=source_prefix,
            destination_bucket=destination_bucket,
            destination_key=destination_key,
            object_keys=[item.key for item in batch_objects],
            batch_number=batch_number,
            read_chunk_size=read_chunk_size,
            part_size=part_size,
        )

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        pending: set[Future[BatchResult]] = set()

        for _ in range(max_workers):
            try:
                batch_number, batch_objects = next(batch_iter)
            except StopIteration:
                break
            pending.add(submit_batch(executor, batch_number, batch_objects))

        while pending:
            done, pending = wait(pending, return_when=FIRST_COMPLETED)

            completed_results = [future.result() for future in done]
            results.extend(completed_results)

            for _ in completed_results:
                try:
                    batch_number, batch_objects = next(batch_iter)
                except StopIteration:
                    continue
                pending.add(submit_batch(executor, batch_number, batch_objects))

    return sorted(results, key=lambda result: result.batch_number)


def format_duration(duration_seconds: float) -> str:
    total_seconds = max(0, int(round(duration_seconds)))
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)

    if hours:
        return f"{hours}h {minutes}m {seconds}s"
    if minutes:
        return f"{minutes}m {seconds}s"
    return f"{seconds}s"


def build_processing_done_text(
    *,
    environment_name: str,
    duration_seconds: float,
    total_files: int,
    zip_size_bytes: int,
    destination_bucket: str,
    uploaded_location: str,
    error_msg: str | None,
) -> str:
    dur_str = format_duration(duration_seconds)
    zip_size_mb = zip_size_bytes / (1024 * 1024)

    if error_msg:
        return (
            f":x: *CE Registry ZIP bundle failed* ({environment_name})\n"
            f">*Duration:* {dur_str}\n"
            f">*Error:* {error_msg}"
        )

    return (
        f":white_check_mark: *CE Registry ZIP bundle succeeded* ({environment_name})\n"
        f">*Files:* {total_files:,}\n"
        f">*ZIP size:* {zip_size_mb:.2f} MB\n"
        f">*Uploaded:* `s3://{destination_bucket}/{uploaded_location}`\n"
        f">*Duration:* {dur_str}"
    )


def send_processing_done_webhook(
    webhook_url: str,
    *,
    text: str,
    timeout: int = DEFAULT_TIMEOUT_SECONDS,
) -> None:
    body = json.dumps({"text": text}).encode("utf-8")
    req = request.Request(
        webhook_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with request.urlopen(req, timeout=timeout) as response:
        status_code = getattr(response, "status", None)
        if status_code is not None and not 200 <= status_code < 300:
            raise RuntimeError(f"webhook returned unexpected status code: {status_code}")


def build_output_manifest(
    *,
    source_objects: list[SourceObject],
    destination_bucket: str,
    destination_prefix: str,
    results: list[BatchResult],
) -> dict[str, Any]:
    return {
        "batch_count": len(results),
        "destination_bucket": destination_bucket,
        "destination_prefix": destination_prefix.strip("/"),
        "total_files": sum(result.object_count for result in results),
        "total_input_bytes": sum(item.size_bytes for item in source_objects),
        "zip_files": [result.destination_key for result in results],
        "zip_size_bytes": sum(result.zip_size_bytes for result in results),
    }


def write_output_manifest(manifest_path: str | None, manifest: dict[str, Any]) -> None:
    if not manifest_path:
        return

    path = Path(manifest_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(manifest), encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Stream JSON objects from S3 into ZIP batches")
    parser.add_argument("--source-bucket", required=True)
    parser.add_argument("--source-prefix", default="")
    parser.add_argument("--destination-bucket", required=True)
    parser.add_argument("--destination-prefix", default="")
    parser.add_argument("--max-uncompressed-zip-size-bytes", type=int, default=200 * 1024 * 1024)
    parser.add_argument("--batch-size", type=int, default=1000)
    parser.add_argument("--max-workers", type=int, default=4)
    parser.add_argument("--max-input-files", type=int, default=None)
    parser.add_argument("--region", default=None)
    parser.add_argument("--endpoint-url", default=None)
    parser.add_argument("--read-chunk-size", type=int, default=1024 * 1024)
    parser.add_argument("--part-size", type=int, default=8 * 1024 * 1024)
    parser.add_argument("--manifest-path", default=None)
    return parser


def get_uploaded_location(destination_prefix: str, results: list[BatchResult]) -> str:
    if len(results) == 1:
        return results[0].destination_key

    cleaned_prefix = destination_prefix.strip("/")
    return f"{cleaned_prefix}/" if cleaned_prefix else ""


def send_completion_webhook(
    webhook_url: str | None,
    *,
    environment_name: str,
    started_at: float,
    destination_bucket: str,
    destination_prefix: str,
    results: list[BatchResult],
    error_msg: str | None,
) -> None:
    if not webhook_url:
        return

    text = build_processing_done_text(
        environment_name=environment_name,
        duration_seconds=time.monotonic() - started_at,
        total_files=sum(result.object_count for result in results),
        zip_size_bytes=sum(result.zip_size_bytes for result in results),
        destination_bucket=destination_bucket,
        uploaded_location=get_uploaded_location(destination_prefix, results),
        error_msg=error_msg,
    )
    send_processing_done_webhook(webhook_url, text=text)


def main() -> int:
    args = build_parser().parse_args()

    client_kwargs = {}
    if args.region:
        client_kwargs["region_name"] = args.region
    if args.endpoint_url:
        client_kwargs["endpoint_url"] = args.endpoint_url

    client = boto3.client("s3", **client_kwargs)
    webhook_url = os.getenv("WEBHOOK_URL")
    environment_name = os.getenv("ENVIRONMENT", "staging")

    started_at = time.monotonic()
    results: list[BatchResult] = []
    source_objects = list_json_keys(
        client,
        args.source_bucket,
        args.source_prefix,
        limit=args.max_input_files,
    )

    try:
        results = process_batches(
            client,
            source_bucket=args.source_bucket,
            source_prefix=args.source_prefix,
            destination_bucket=args.destination_bucket,
            destination_prefix=args.destination_prefix,
            max_uncompressed_zip_size_bytes=args.max_uncompressed_zip_size_bytes,
            max_workers=args.max_workers,
            source_objects=source_objects,
            max_batch_size=args.batch_size,
            read_chunk_size=args.read_chunk_size,
            part_size=args.part_size,
        )
    except Exception as exc:
        send_completion_webhook(
            webhook_url,
            environment_name=environment_name,
            started_at=started_at,
            destination_bucket=args.destination_bucket,
            destination_prefix=args.destination_prefix,
            results=results,
            error_msg=str(exc),
        )
        raise

    send_completion_webhook(
        webhook_url,
        environment_name=environment_name,
        started_at=started_at,
        destination_bucket=args.destination_bucket,
        destination_prefix=args.destination_prefix,
        results=results,
        error_msg=None,
    )

    manifest = build_output_manifest(
        source_objects=source_objects,
        destination_bucket=args.destination_bucket,
        destination_prefix=args.destination_prefix,
        results=results,
    )
    write_output_manifest(args.manifest_path, manifest)
    print(json.dumps(manifest), file=sys.stdout)

    for result in results:
        print(
            f"batch={result.batch_number} objects={result.object_count} destination={result.destination_key}",
            file=sys.stdout,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
