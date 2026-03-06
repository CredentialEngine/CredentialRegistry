from __future__ import annotations

import pytest

from main import (
    S3UploadWriter,
    SourceObject,
    build_destination_key,
    build_output_manifest,
    chunked_by_estimated_size,
    stream_objects_to_zip,
)


def test_chunked_by_estimated_size_splits_items_by_target_bytes() -> None:
    assert list(
        chunked_by_estimated_size(
            [
                SourceObject("a", 40),
                SourceObject("b", 50),
                SourceObject("c", 30),
                SourceObject("d", 70),
            ],
            max_uncompressed_zip_size_bytes=100,
        )
    ) == [
        [SourceObject("a", 40), SourceObject("b", 50)],
        [SourceObject("c", 30), SourceObject("d", 70)],
    ]


def test_chunked_by_estimated_size_respects_optional_batch_size_cap() -> None:
    assert list(
        chunked_by_estimated_size(
            [
                SourceObject("a", 10),
                SourceObject("b", 10),
                SourceObject("c", 10),
            ],
            max_uncompressed_zip_size_bytes=100,
            max_batch_size=2,
        )
    ) == [
        [SourceObject("a", 10), SourceObject("b", 10)],
        [SourceObject("c", 10)],
    ]


@pytest.mark.parametrize(
    ("max_uncompressed_zip_size_bytes", "max_batch_size", "error_message"),
    [
        (0, None, "max_uncompressed_zip_size_bytes must be greater than zero"),
        (-1, None, "max_uncompressed_zip_size_bytes must be greater than zero"),
        (1, 0, "max_batch_size must be greater than zero"),
        (1, -1, "max_batch_size must be greater than zero"),
    ],
)
def test_chunked_by_estimated_size_validates_inputs(
    max_uncompressed_zip_size_bytes: int,
    max_batch_size: int | None,
    error_message: str,
) -> None:
    with pytest.raises(ValueError, match=error_message):
        list(
            chunked_by_estimated_size(
                [SourceObject("a", 1)],
                max_uncompressed_zip_size_bytes=max_uncompressed_zip_size_bytes,
                max_batch_size=max_batch_size,
            )
        )


def test_build_destination_key_normalizes_prefix() -> None:
    assert build_destination_key("out", 7) == "out/batch-00007.zip"
    assert build_destination_key("/out/", 7) == "out/batch-00007.zip"
    assert build_destination_key("", 7) == "batch-00007.zip"


def test_build_output_manifest_lists_uploaded_zip_files() -> None:
    manifest = build_output_manifest(
        source_objects=[],
        destination_bucket="dest-bucket",
        destination_prefix="/archives/run-1/",
        results=[],
    )

    assert manifest == {
        "batch_count": 0,
        "destination_bucket": "dest-bucket",
        "destination_prefix": "archives/run-1",
        "total_files": 0,
        "total_input_bytes": 0,
        "zip_files": [],
        "zip_size_bytes": 0,
    }


@pytest.mark.parametrize("read_chunk_size", [0, -1])
def test_stream_objects_to_zip_validates_read_chunk_size(read_chunk_size: int) -> None:
    with pytest.raises(ValueError, match="read_chunk_size must be greater than zero"):
        stream_objects_to_zip(
            object(),
            source_bucket="source",
            source_prefix="graphs/",
            destination_bucket="dest",
            destination_key="archives/batch-00001.zip",
            object_keys=["graphs/1.json"],
            batch_number=1,
            read_chunk_size=read_chunk_size,
            part_size=5 * 1024 * 1024,
        )


@pytest.mark.parametrize("part_size", [0, 1024, 5 * 1024 * 1024 - 1])
def test_s3_upload_writer_validates_minimum_part_size(part_size: int) -> None:
    with pytest.raises(ValueError, match="part_size must be at least 5 MiB"):
        S3UploadWriter(object(), "dest", "batch.zip", part_size=part_size)
