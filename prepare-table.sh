#!/bin/sh

if [ "x$REMOTE_CONTAINERS" = "xtrue" ] || [ "x$USER_CONTAINERS_START" = "xtrue" ]; then
    echo "We are inside VS Code devcontainer."
    echo "This script must be run on the host machine, not inside the container."
    echo "Exiting."
    exit 1
fi
