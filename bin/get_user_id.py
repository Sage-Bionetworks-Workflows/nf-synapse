#!/usr/bin/env python3

import synapseclient


def get_user_id(syn: synapseclient.Synapse) -> None:
    user = syn.getUserProfile()
    return user.ownerId


if __name__ == "__main__":
    syn = synapseclient.Synapse()
    syn.login(silent=True)
    user_id = get_user_id(syn=syn)
    print(user_id, end="")
