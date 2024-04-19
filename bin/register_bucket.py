#!/usr/bin/env python3

"""
Registers external S3 bucket as a Storage Location in Synapse.
Prints the Storage Location ID.
"""

import sys

import synapseclient


bucket = sys.argv[1]
base_key = sys.argv[2]

syn = synapseclient.Synapse()
syn.login(silent=True)

storage_location_id = syn.createStorageLocationSetting(
    storage_type="ExternalS3Storage",
    upload_type="S3",
    bucket=bucket,
    baseKey=base_key,
)["storageLocationId"]

print(storage_location_id, end="")
