#!/usr/bin/env python3

"""
Gets the Synapse user ID number of the current user and prints it.
"""

import synapseclient


syn = synapseclient.Synapse()
syn.login(silent=True)

user_id = syn.getUserProfile().ownerId

print(user_id, end="")
