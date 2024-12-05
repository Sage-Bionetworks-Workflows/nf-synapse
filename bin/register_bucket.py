#!/usr/bin/env python3

"""
Registers external S3 bucket as a Storage Location in Synapse. This also registers the
bucket as a storage location for the parent container without updating the default
upload location that was already set on the container.

Prints the Storage Location ID.
"""

import sys

import synapseclient
from synapseclient.core.async_utils import wrap_async_to_sync

from synapseclient.api.entity_services import get_upload_destination

bucket = sys.argv[1]
base_key = sys.argv[2]
parent_id = sys.argv[3]

syn = synapseclient.Synapse()
syn.login(silent=True)

storage_location_id = syn.createStorageLocationSetting(
    storage_type="ExternalS3Storage",
    upload_type="S3",
    bucket=bucket,
    baseKey=base_key,
)["storageLocationId"]

# Grab the current settings for the container being indexed to and add the new storage
# location to the list of storage locations. This is necessary to ensure that the
# current default storage location is set retained on the container.
current_container_settings = syn.getProjectSetting(
    project=parent_id, setting_type="upload"
)

container_storage_list_needs_update = False
has_existing_setting = current_container_settings is not None and "locations" in current_container_settings and current_container_settings[
    "locations"]

if has_existing_setting:
    storage_locations_for_container = current_container_settings["locations"]
    if storage_location_id not in storage_locations_for_container:
        storage_locations_for_container.append(storage_location_id)
        container_storage_list_needs_update = True
else:
    storage_locations_for_container = []
    upload_destination = wrap_async_to_sync(
        coroutine=get_upload_destination(
            entity_id=parent_id,
            synapse_client=syn,
        ),
        syn=syn,
    )

    if upload_destination and "storageLocationId" in upload_destination:
        storage_locations_for_container.append(
            upload_destination["storageLocationId"])
        container_storage_list_needs_update = True
    storage_locations_for_container.append(storage_location_id)

if container_storage_list_needs_update:
    syn.setStorageLocation(
        entity=parent_id, storage_location_id=storage_locations_for_container)


print(storage_location_id, end="")
