#!/usr/bin/env python3

import os
import re
import sys

import synapseclient
from synapseclient.core.utils import md5_for_file_hex
from synapseclient.models import File


def clean_file_name(file: str) -> str:
    """Cleans the file name by replacing special characters and spaces with underscores.

    Arguments:
        file: Name of the file.

    Returns:
        filename: Clean file name.
    """
    file_name = os.path.basename(file)
    clean_file_name = re.sub(r"[^A-Za-z0-9 _.+'()-]", "_", file_name)
    return clean_file_name


def create_file_handle(
    syn: synapseclient.Synapse,
    storage_id: str,
    uri: str,
    file_name: str,
    md5_checksum: str,
) -> str:
    """Creates an external S3 file handle.

    Arguments:
        syn: Synapse client object.
        storage_id: Storage location ID.
        uri: S3 URI of the file.
        file_name: Name of the file.
        md5_checksum: MD5 checksum.

    Returns:
        file_handle_id: File handle ID
    """
    bucket, key = re.fullmatch(r"s3://([^/]+)/(.*)", uri).groups()
    file_handle = syn.create_external_s3_file_handle(
        bucket_name=bucket,
        s3_file_key=key,
        file_path=file_name,
        storage_location_id=storage_id,
        md5=md5_checksum,
    )
    return file_handle["id"]


if __name__ == "__main__":
    storage_id = sys.argv[1]
    file = sys.argv[2]
    uri = sys.argv[3]
    parent_id = sys.argv[4]

    syn = synapseclient.Synapse()
    syn.login(silent=True)

    md5_checksum = md5_for_file_hex(filename=file)
    file_name = clean_file_name(file=file)
    file_handle_id = create_file_handle(
        syn=syn,
        storage_id=storage_id,
        uri=uri,
        file_name=file_name,
        md5_checksum=md5_checksum,
    )
    file = File(
        name=file_name,
        path=file,
        parent_id=parent_id,
        data_file_handle_id=file_handle_id,
    ).store()
    print(f"{uri},{file.id}", end="")
