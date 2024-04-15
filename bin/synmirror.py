#!/usr/bin/env python3

import os
import sys

import synapseclient
from synapseclient.models import Folder
import pandas as pd


def _create_folder(name: str, parent_id: str) -> str:
    folder = Folder(name=name, parent_id=parent_id).store()
    return folder.id


# TODO add this functionality to synapseclient
# https://sagebionetworks.jira.com/browse/SYNPY-1463
def mirror_folder_structure(objects: str, s3_prefix: str, parent_id: str) -> None:
    s3_prefix = s3_prefix.rstrip("/") + "/"
    mapping = {s3_prefix: parent_id}
    object_uri_list = []
    folder_id_list = []
    with open(objects, "r") as infile:
        for line in infile:
            object_uri = line.rstrip()
            head, _ = os.path.split(object_uri)
            head += "/"  # Keep trailing slash for consistency
            relhead = head.replace(s3_prefix, "")
            folder_uri = s3_prefix
            for folder in relhead.rstrip("/").split("/"):
                if folder == "":
                    continue
                parent_id = mapping[folder_uri]
                folder_uri += f"{folder}/"
                if folder_uri not in mapping:
                    folder_id = _create_folder(folder, parent_id)
                    mapping[folder_uri] = folder_id
            object_uri_list.append(object_uri)
            folder_id_list.append(mapping[folder_uri])
    df = pd.DataFrame({"object_uri": object_uri_list, "folder_id": folder_id_list})
    df.to_csv("parent_ids.csv", index=False)


if __name__ == "__main__":
    objects = sys.argv[1]
    s3_prefix = sys.argv[2]
    parent_id = sys.argv[3]

    syn = synapseclient.Synapse()
    syn.login(silent=True)

    mirror_folder_structure(objects=objects, s3_prefix=s3_prefix, parent_id=parent_id)
