#!/usr/bin/env python3

import sys

import sevenbridges as sbg


def get_sevenbridges_file(sbg_id: str):
    api = sbg.Api()
    download_file = api.files.get(sbg_id)
    download_file.download(download_file.name)


if __name__ == "__main__":
    sbg_id = sys.argv[1]
    get_sevenbridges_file(sbg_id)
