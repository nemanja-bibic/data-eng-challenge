#!/bin/sh
# Registers the MirrorName search attribute that PeerDB's Temporal workflows
# tag runs with. Without it, flow-api fails when starting a mirror.

sleep 5

if ! temporal operator search-attribute list | grep -w MirrorName >/dev/null 2>&1; then
    temporal operator search-attribute create --name MirrorName --type Text --namespace default
fi

tini -s -- sleep infinity
