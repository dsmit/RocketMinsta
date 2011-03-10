#!/bin/bash

function error
{
    echo -e "\n$*" >&2
    exit 1
}

[ -e "config.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read configuration"

function getqcc
{
    local i=0
    local qcc=""

    echo "Looking for a QuakeC compiller" >&2

    while true; do
        qcc="${QCC[$i]}"

        [ x"$qcc" = x ] && error "Failed to find a QuakeC compiller"

        echo -n " -- Trying $qcc... " >&2
        which "$qcc" &>/dev/null && break

        echo -e "\e[31;1mmissing\e[0m" >&2
        let i++
    done

    echo -e "\e[32;1mfound\e[0m" >&2
    echo "$qcc"
}

[ -e "rocketminsta.cfg" ] || error "rocketminsta.cfg wasn't found"
USEQCC="$(getqcc)"

function buildqc
{
    qcdir="$QCSOURCE/$1"

    echo " -- Building $qcdir" >&2
    pushd "$qcdir" &>/dev/null || error "Build target does not exist? huh"
    $USEQCC $QCCFLAGS || error "Failed to build $qcdir"
    popd &>/dev/null
}

BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"

echo "#define RM_BUILD_DATE \"$(date +"%F %T %Z") (git build)\""          >  "$QCSOURCE"/common/rm_auto.qh
echo "#define RM_BUILD_NAME \"RocketMinsta-$BRANCH\"" >> "$QCSOURCE"/common/rm_auto.qh

buildqc server/
mv -v progs.dat "$SVPROGS"

buildqc client/
mv -v csprogs.dat "$CSPROGS"

rm -v "$QCSOURCE"/common/rm_auto.qh

cp -v "rocketminsta.cfg" "$NEXDATA"
mkdir -pv "$NEXDATA/rm-custom"
cp -v rm-custom/* "$NEXDATA/rm-custom"

function listcustom()
{
    find "$NEXDATA/rm-custom" -name "*.cfg" | while read cfg; do
        echo -e "\t\t$cfg : $(head -1 "$cfg" | sed -e 's@//cfgname:@@')"
    done
}

cat <<EOF
**************************************************

    RocketMinsta has been built successfully
    
    Server QC progs:
        $SVPROGS
    
    Client QC progs:
        $CSPROGS
        
    CVAR defaults for server configuration:
        $NEXDATA/rocketminsta.cfg
    
    Optional custom configurations:
        $NEXDATA/rm-custom
$(listcustom)

    Please make sure all of these files are
    accessible by Nexuiz. Then add the following
    lines at top of your server config:
    
        exec rocketminsta.cfg
        set sv_progs $(echo "$SVPROGS" | sed -e 's@.*/@@g')
        set csqc_progname $(echo "$CSPROGS" | sed -e 's@.*/@@g')

    If you'd like to use one of the custom configurations,
    add the following at the bottom of your config:
        
        exec rm-custom/NAME_OF_CUSTOM_CONFIG.cfg

**************************************************
EOF
