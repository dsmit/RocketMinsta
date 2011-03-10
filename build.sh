#!/bin/bash

RELEASE=0
BUILD_DATE="$(date +"%F %T %Z")"
BUILD_DATE_PLAIN="$(date +%y%m%d%H%M%S)"
BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"

function error
{
    echo -e "\n$*" >&2
    exit 1
}

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

function buildqc
{
    qcdir="$QCSOURCE/$1"

    echo " -- Building $qcdir" >&2
    pushd "$qcdir" &>/dev/null || error "Build target does not exist? huh"
    $USEQCC $QCCFLAGS || error "Failed to build $qcdir"
    popd &>/dev/null
}

function buildall
{
    # $1 = suffix
    # $2 = desc
    
    USEQCC="$(getqcc)"

    echo "#define RM_BUILD_DATE \"$BUILD_DATE ($2)\""          >  "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_NAME \"RocketMinsta$1\"" >> "$QCSOURCE"/common/rm_auto.qh

    buildqc server/
    mv -v progs.dat "$SVPROGS"

    buildqc client/
    mv -v csprogs.dat "$CSPROGS"

    rm -v "$QCSOURCE"/common/rm_auto.qh
}

function listcustom()
{
    find "$NEXDATA/rm-custom" -name "*.cfg" | while read cfg; do
        echo -e "\t\t$cfg : $(head -1 "$cfg" | sed -e 's@//cfgname:@@')"
    done
}

################################################################################

[ -e "config.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read configuration"

if [ "$1" = "release" ]; then
    RELEASE=1
    [ -e "releaseconfig.sh" ] || error "No release configuration file found. Please run \`cp EXAMPLE_releaseconfig.sh releaseconfig.sh', edit releaseconfig.sh and try again."
    . "releaseconfig.sh" || error "Failed to read release configuration"
    
    [ -n "$RELEASE_SUFFIX"     ] && RELEASE_REALSUFFIX="-$RELEASE_SUFFIX"
    [ z"$BRANCH" = z"master"   ] || RELEASE_REALSUFFIX="-$BRANCH$RELEASE_REALSUFFIX"
    
    if [ -n "$RELEASE_DEFAULTCFG" ]; then
        if [ -n "$RELEASE_REALSUFFIX" ]; then
            RELEASE_REALSUFFIX="${RELEASE_REALSUFFIX}_cfg$RELEASE_DEFAULTCFG"
        else
            RELEASE_REALSUFFIX="-cfg$RELEASE_DEFAULTCFG"
        fi
        
        [ -e "rm-custom/$RELEASE_DEFAULTCFG.cfg" ] || error "Default configuration '$RELEASE_DEFAULTCFG.cfg' does not exist in rm-custom"
    fi
    
    PKGNAME="RocketMinsta${RELEASE_REALSUFFIX}"
    RELEASE_PKGNAME="${PKGNAME}_$BUILD_DATE_PLAIN"
    RELEASE_PKGPATH="$(readlink -f "$RELEASE_PKGPATH")"
    mkdir "$RELEASE_PKGPATH/$RELEASE_PKGNAME" || error "Failed to create package directory"

    NEXDATA="$(readlink -f "$RELEASE_PKGPATH/$RELEASE_PKGNAME")"
    SVPROGS="$NEXDATA/sv_mod.dat"
    CSPROGS="$NEXDATA/cl_mod.dat"
    
    buildall $RELEASE_REALSUFFIX "$RELEASE_DESCRIPTION"
    
    cp -v "rocketminsta.cfg" "$NEXDATA"
    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        mkdir -pv "$NEXDATA/rm-custom"
        cp -v rm-custom/* "$NEXDATA/rm-custom"
    fi

    if [ -n "$RELEASE_DEFAULTCFG" ]; then
        cat "rm-custom/$RELEASE_DEFAULTCFG.cfg" >> "$NEXDATA/rocketminsta.cfg"
        sed -i "/exec rocketminsta.cfg/d" "$NEXDATA/rocketminsta.cfg" # Without this, a recursive include will occur
    fi
    
    cat <<EOF > "$NEXDATA/README.rmrelease"

This is an auto generated $PKGNAME release package, built at $BUILD_DATE. Installation:
    
    1) Extract the contents of this package into your Nexuiz data directory (typically ~/.nexuiz/data/)
    2) Edit your server config and add the following lines at very top:
        
        exec rocketminsta.cfg
        set sv_progs $(echo "$SVPROGS" | sed -e 's@.*/@@g')
        set csqc_progname $(echo "$CSPROGS" | sed -e 's@.*/@@g')
EOF

    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        cat <<EOF >> "$NEXDATA/README.rmrelease"
        
        If you'd like to use one of the custom configurations,
        add the following at the bottom of your config:
        
            exec rm-custom/NAME_OF_CUSTOM_CONFIG.cfg
        
        The following configurations were included at build time: `ls rm-custom/*.cfg | while read line; do line=${line##rm-custom/}; echo -n "$line "; done`
EOF
    fi

    cat <<EOF >> "$NEXDATA/README.rmrelease"
    3) Start the server and enjoy.

RocketMinsta project: https://github.com/nexAkari/RocketMinsta

EOF

    prepackage "$RELEASE_PKGPATH/$RELEASE_PKGNAME" || error "prepackage failed"

    pushd "$NEXDATA" &>/dev/null
    tar -zcvf "$RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz" * | while read line; do
        echo "Adding file: $line"
    done
    popd &>/dev/null

    if [ $RELEASE_CLEANUP -eq 1 ]; then
        rm -vrf "$RELEASE_PKGPATH/$RELEASE_PKGNAME"
    fi

    postpackage "$RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz" || error "postpackage failed"

    cat << EOF
**************************************************

    Finished $PKGNAME release
    
    Package path:
        $RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz

**************************************************
EOF

    exit
fi

buildall $BRANCH "git build"

cp -v "rocketminsta.cfg" "$NEXDATA"
mkdir -pv "$NEXDATA/rm-custom"
cp -v rm-custom/* "$NEXDATA/rm-custom"

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
