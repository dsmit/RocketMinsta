#!/bin/bash

INCLUDE=1
. rmlib.sh || exit 1

require ./build.sh

function finish
{
    echo "Finished updating ／人◕ ‿‿ ◕人＼"
    exit 0
}

[ -e "updconfig.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_updconfig.sh updconfig.sh', edit updconfig.sh and try again."
. "updconfig.sh" || error "Failed to read configuration"

BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"

if [ "$1" != "rebuild" ]; then
    echo " -- Updating $BRANCH"
    git fetch || error "git fetch failed"
    if [ "$(git merge origin/$BRANCH || error "git merge failed")" = "Already up-to-date." ] && [ "$1" != "force" ]; then
        echo "Already up to date, exiting."
        exit 0
    fi
fi

if [ "$1" = "update-only" ]; then
    echo "Not building the mod, update-only specified."
    exit 0
fi

echo " -- Rebuilding the mod"
./build.sh || error "Build failed"

[ -z "$RCON_ADDRESS" ] && finish

echo " -- Sending RCON commands"
which netcat &>/dev/null || error "Cannot use RCON: netcat is not installed"

i=0
while true; do
    cmd="${RCON_COMMANDS[$((i++))]}"
    [ x"$cmd" = x ] && finish
    rconsend "$cmd"
done

finish

