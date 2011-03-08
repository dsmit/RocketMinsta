#!/bin/bash

function error
{
    echo -e "\n$*" >&2
    exit 1
}

function rconsend
{
    printf "\377\377\377\377rcon %s %s" $RCON_PASSWORD "$1" | netcat -uc $RCON_ADDRESS $RCON_PORT
}

[ -e "updconfig.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_updconfig.sh updconfig.sh', edit updconfig.sh and try again."
. "updconfig.sh" || error "Failed to read configuration"

BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"

echo " -- Updating $BRANCH"
git fetch || error "git fetch failed"
if [ "$(git merge origin/$BRANCH || error "git merge failed")" = "Already up-to-date." ] && [ "$1" != "force" ]; then
    echo "Already up to date, exiting."
    exit 0
fi

echo " -- Rebuilding the mod"
./build.sh || error "Build failed"

[ -z "$RCON_ADDRESS" ] && exit 0

echo " -- Sending RCON commands"
which netcat &>/dev/null || error "Cannot use RCON: netcat is not installed"

i=0
while true; do
    cmd="${RCON_COMMANDS[$((i++))]}"
    [ x"$cmd" = x ] && exit 0
    rconsend "$cmd"
done
