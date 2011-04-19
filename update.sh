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

[ -e "config.sh" ] || error "No build configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read build configuration"

. xonotic-conf.sh || error "Failed to read xonotic-conf"

BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"

if [ "$1" != "rebuild" ]; then
    upd=0

    echo " -- Updating $BRANCH"
    git fetch || error "git fetch failed"
    if [ "$(git merge origin/$BRANCH || error "git merge failed")" = "Already up-to-date." ]; then
        echo "$BRANCH is already up to date."
        let upd++
    fi
    
    echo " -- Updating $XONDATA_RM_BRANCH"
    
    if [ "$(readlink -f "$QCSOURCE")" = "$(readlink -f "qcsrc")" ]; then
        echo "QCSOURCE points to $(readlink -f "qcsrc"), correcting to $(readlink -f "xonotic-git/qcsrc")"
        QCSOURCE="$(readlink -f "xonotic-git/qcsrc")"
        
        [ -e "$QCSOURCE" ] || error "QCSOURCE doesn't exist, WTF?!"
    fi
    
    pushd "$QCSOURCE" &> /dev/null || error "cd failed (?!)"
    git checkout "$XONDATA_RM_BRANCH" || error "git checkout failed"
    
    if [ "$(git pull || error "git pull failed")" = "Already up-to-date." ]; then
        echo "$XONDATA_RM_BRANCH is already up to date."
        let upd++
    fi
    popd &> /dev/null
    
    if [ $upd -eq 2 ] && [ "$1" != "force" ]; then
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

