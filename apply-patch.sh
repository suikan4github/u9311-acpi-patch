#!/bin/sh

if [ "x$REMOTE_CONTAINERS" = "xtrue" ] || [ "x$USER_CONTAINERS_START" = "xtrue" ]; then
    echo "We are inside VS Code devcontainer."
    echo "OK. Let's continue."
fi
