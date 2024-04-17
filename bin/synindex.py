#!/usr/bin/env python3

# Import packages
import hashlib
import os
import re
import sys

import synapseclient
from synapseclient.models import File


def compute_md5_checksum(file: str) -> str:
    hash_md5 = hashlib.md5()
    with open(file, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    checksum = hash_md5.hexdigest()
    return checksum


def clean_file_name(file: str) -> str:
    filename = os.path.basename(file)
    filename = re.sub(r"[^A-Za-z0-9 _.+'()-]", "_", filename)
    return filename


def create_file_handle(
    syn: synapseclient.Synapse,
    # storage_id: str,
    uri: str,
    file_name: str,
    parent: str,
    md5_checksum: str,
) -> str:
    bucket, key = re.fullmatch(r"s3://([^/]+)/(.*)", uri).groups()
    file_handle = syn.create_external_s3_file_handle(
        bucket_name=bucket,
        s3_file_key=key,
        file_path=file_name,
        parent=parent,
        # storage_location_id=storage_id,
        md5=md5_checksum,
    )
    return file_handle["id"]


def store_file(file_name: str, parent_id: str, file_handle_id: str) -> File:
    file = File(
        name=file_name,
        parent_id=parent_id,
        data_file_handle_id=file_handle_id,
    )
    file.store()
    return file


if __name__ == "__main__":
    storage_id = sys.argv[1]
    file = sys.argv[2]
    uri = sys.argv[3]
    parent_id = sys.argv[4]

    syn = synapseclient.Synapse()
    syn.login(silent=True)

    md5_checksum = compute_md5_checksum(file=file)
    file_name = clean_file_name(file=file)
    file_handle_id = create_file_handle(
        syn=syn,
        # storage_id=storage_id,
        uri=uri,
        file_name=file_name,
        parent=parent_id,
        md5_checksum=md5_checksum,
    )

    file = store_file(
        file_name=file_name, parent_id=parent_id, file_handle_id=file_handle_id
    )

    print(f"{uri},{file.id}", end="")
