#!/usr/bin/env python3

import sys

import synapseclient


def create_storage_location(
    syn: synapseclient.Synapse, bucket: str, base_key: str
) -> int:
    """Creates an external S3 storage location in Synapse.

    Args:
        syn: Synapse client object.
        bucket: S3 bucket name.
        base_key: Base key in the S3 bucket.

    Returns:
        storage_location_id: ID number of the new storage location.
    """
    storage_location = syn.createStorageLocationSetting(
        storage_type="ExternalS3Storage",
        upload_type="S3",
        bucket=bucket,
        baseKey=base_key,
    )
    storage_location_id = storage_location["storageLocationId"]
    return storage_location_id


if __name__ == "__main__":
    bucket = sys.argv[1]
    base_key = sys.argv[2]
    syn = synapseclient.Synapse()
    syn.login(silent=True)
    storage_location_id = create_storage_location(
        syn=syn, bucket=bucket, base_key=base_key
    )
    print(storage_location_id, end="")
