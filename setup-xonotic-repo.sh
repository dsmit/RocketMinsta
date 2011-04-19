#!/bin/bash

INCLUDE=1
. rmlib.sh || exit 1

. xonotic-conf.sh || error "Failed to read xonotic-conf"

if [ -e "xonotic-git" ]; then
    echo "Repository seems to already exist, attempting to fix branch..."
    cd "xonotic-git" || error "cd failed (?!)"
    git checkout "$XONDATA_RM_BRANCH" || error "git checkout failed"
    echo "Done, now at branch $XONDATA_RM_BRANCH"
    exit 0
fi

[ -e "config.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read configuration"


if [ "$(readlink -f "$QCSOURCE")" != "$(readlink -f "qcsrc")" ]; then
    echo "QCSOURCE explicitly points to a source directory other than $(readlink -f "qcsrc"), not setting up a Xonotic data repository"
    exit 0
fi

cat << EOF

To build the Xonotic port of RM, you must have a xonotic-data.pk3dir repository set up.
If you have already cloned Xonotic from git, quit now and edit your configuration file so QCSOURCE points to:
    /path/to/xonotic/data/xonotic-data.pk3dir/qcsrc
    
Then cd into that directory, do:
    git pull && git checkout $XONDATA_RM_BRANCH
    
If that succeeded, try building the mod.
    
In case you DO NOT have a cloned Xonotic repo, this script can set it up for you.
Note: the xonotic-data.pk3dir repository is large, and will take a while to clone.

Press ENTER to proceed and clone the xonotic-data.pk3dir repository
Press Ctrl+C to abort the operation and exit

EOF

read

git clone "$XONDATA_REPO_URL" "xonotic-git" || error "git clone failed"
cd "xonotic-git" || error "cd failed (?!)"
git checkout "$XONDATA_RM_BRANCH" || error "git checkout failed"

echo "Repository setup finished"
