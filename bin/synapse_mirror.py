#!/usr/bin/env python3

import os
import sys

import pandas as pd
import synapseclient
from synapseclient.models import Folder


# TODO add this functionality to synapseclient
# https://sagebionetworks.jira.com/browse/SYNPY-1463
def mirror_folder_structure(objects_file: str, s3_prefix: str, parent_id: str) -> None:
    """Recreates the folder structure of an S3 bucket within a Synapse parent location.

    Arguments:
        objects_file: Name of the file containing the object URIs.
        s3_prefix: S3 URI prefix.
        parent_id: Synapse ID of the parent location.
    """
    s3_prefix = s3_prefix.rstrip("/") + "/"
    mapping = {s3_prefix: parent_id}
    object_uri_list = []
    folder_id_list = []
    with open(objects_file, "r") as infile:
        for line in infile:
            object_uri = line.rstrip()
            head, _ = os.path.split(object_uri)
            head += "/"
            relhead = head.replace(s3_prefix, "")
            folder_uri = s3_prefix
            for folder in relhead.rstrip("/").split("/"):
                if folder == "":
                    continue
                parent_id = mapping[folder_uri]
                folder_uri += f"{folder}/"
                if folder_uri not in mapping:
                    folder_id = Folder(name=folder, parent_id=parent_id).store().id
                    mapping[folder_uri] = folder_id
            object_uri_list.append(object_uri)
            folder_id_list.append(mapping[folder_uri])

    df = pd.DataFrame({"object_uri": object_uri_list, "folder_id": folder_id_list})
    df.to_csv("parent_ids.csv", index=False)


if __name__ == "__main__":
    objects_file = sys.argv[1]
    s3_prefix = sys.argv[2]
    parent_id = sys.argv[3]

    syn = synapseclient.Synapse()
    syn.login(silent=True)

    mirror_folder_structure(
        objects_file=objects_file, s3_prefix=s3_prefix, parent_id=parent_id
    )
