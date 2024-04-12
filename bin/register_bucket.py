#!/usr/bin/env python3

import json
import sys

import synapseclient


def get_storage_location_id(
    syn: synapseclient.Synapse, bucket: str, base_key: str
) -> str:
    destination = {
        "uploadType": "S3",
        "concreteType": "org.sagebionetworks.repo.model.project.ExternalS3StorageLocationSetting",
        "bucket": bucket,
        "baseKey": base_key,
    }
    destination = syn.restPOST("/storageLocation", body=json.dumps(destination))
    return destination["storageLocationId"]


if __name__ == "__main__":
    bucket = sys.argv[1]
    base_key = sys.argv[2]
    syn = synapseclient.Synapse()
    syn.login(silent=True)
    storage_location_id = get_storage_location_id(syn, bucket, base_key)
    print(storage_location_id, end="")
