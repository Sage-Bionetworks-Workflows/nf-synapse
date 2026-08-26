# tests/test_synapse_index.py

import csv
from unittest.mock import MagicMock

import pytest

from bin.synapse_index import (
    MAPPING_FIELDS,
    clean_file_name,
    create_file_handle,
    write_mapping,
)


class TestCleanFileName:
    def test_returns_basename(self) -> None:
        result = clean_file_name("/some/path/to/file.txt")

        assert result == "file.txt"

    def test_replaces_special_characters_with_underscores(self) -> None:
        result = clean_file_name("/some/path/file@name#test!.txt")

        assert result == "file_name_test_.txt"

    def test_preserves_allowed_characters(self) -> None:
        result = clean_file_name(
            "/some/path/file name_1+test'(abc)-data.csv"
        )

        assert result == "file name_1+test'(abc)-data.csv"

    def test_replaces_path_filename_special_characters_only(self) -> None:
        result = clean_file_name(
            "/directory-with@special/chars/data:file.csv"
        )

        assert result == "data_file.csv"


class TestCreateFileHandle:
    def test_creates_external_s3_file_handle(self) -> None:
        syn = MagicMock()
        syn.create_external_s3_file_handle.return_value = {
            "id": "12345"
        }

        result = create_file_handle(
            syn=syn,
            storage_id="6789",
            uri="s3://example-bucket/path/to/file.txt",
            file_name="file.txt",
            md5_checksum="abc123",
        )

        assert result == "12345"

        syn.create_external_s3_file_handle.assert_called_once_with(
            bucket_name="example-bucket",
            s3_file_key="path/to/file.txt",
            file_path="file.txt",
            storage_location_id="6789",
            md5="abc123",
        )

    def test_preserves_nested_s3_key(self) -> None:
        syn = MagicMock()
        syn.create_external_s3_file_handle.return_value = {
            "id": "12345"
        }

        create_file_handle(
            syn=syn,
            storage_id="6789",
            uri="s3://example-bucket/a/b/c/file.txt",
            file_name="file.txt",
            md5_checksum="abc123",
        )

        syn.create_external_s3_file_handle.assert_called_once_with(
            bucket_name="example-bucket",
            s3_file_key="a/b/c/file.txt",
            file_path="file.txt",
            storage_location_id="6789",
            md5="abc123",
        )

    def test_invalid_s3_uri_raises_error(self) -> None:
        syn = MagicMock()

        with pytest.raises(AttributeError):
            create_file_handle(
                syn=syn,
                storage_id="6789",
                uri="https://example.com/file.txt",
                file_name="file.txt",
                md5_checksum="abc123",
            )

        syn.create_external_s3_file_handle.assert_not_called()


class TestWriteMapping:
    def test_writes_expected_csv(self, tmp_path) -> None:
        mapping_file = tmp_path / "file_info.csv"

        row = {
            "object_uri": "s3://example-bucket/test.txt",
            "synapse_id": "syn111",
            "parent_id": "syn12345678",
            "file_handle_id": "7788",
            "content_md5": "d41d8cd98f00b204e9800998ecf8427e",
            "file_name": "test.txt",
        }

        write_mapping(
            mapping_file=str(mapping_file),
            row=row,
        )

        with mapping_file.open(newline="") as infile:
            reader = csv.DictReader(infile)
            rows = list(reader)

        assert reader.fieldnames == MAPPING_FIELDS
        assert rows == [row]

    def test_overwrites_existing_mapping_file(self, tmp_path) -> None:
        mapping_file = tmp_path / "file_info.csv"

        mapping_file.write_text("old,data\nfoo,bar\n")

        row = {
            "object_uri": "s3://example-bucket/test.txt",
            "synapse_id": "syn111",
            "parent_id": "syn12345678",
            "file_handle_id": "7788",
            "content_md5": "abc123",
            "file_name": "test.txt",
        }

        write_mapping(
            mapping_file=str(mapping_file),
            row=row,
        )

        with mapping_file.open(newline="") as infile:
            reader = csv.DictReader(infile)
            rows = list(reader)

        assert reader.fieldnames == MAPPING_FIELDS
        assert rows == [row]

    def test_all_mapping_fields_are_written_in_expected_order(
        self,
        tmp_path,
    ) -> None:
        mapping_file = tmp_path / "file_info.csv"

        row = {
            "object_uri": "s3://bucket/file.txt",
            "synapse_id": "syn1",
            "parent_id": "syn2",
            "file_handle_id": "3",
            "content_md5": "abc",
            "file_name": "file.txt",
        }

        write_mapping(str(mapping_file), row)

        first_line = mapping_file.read_text().splitlines()[0]

        assert first_line == ",".join(MAPPING_FIELDS)