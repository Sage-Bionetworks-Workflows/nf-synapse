#!/usr/bin/env python3

import synapseclient


def get_user_id(syn: synapseclient.Synapse) -> int:
    """Returns the Synapse user ID of the user who is logged in.

    Arguments:
        syn: Synapse client object

    Returns:
        user_id: Synapse user ID
    """

    user = syn.getUserProfile()
    user_id = user.ownerId
    return user_id


if __name__ == "__main__":
    syn = synapseclient.Synapse()
    syn.login(silent=True)
    user_id = get_user_id(syn=syn)
    print(user_id, end="")
