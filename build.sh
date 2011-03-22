#!/bin/bash

INCLUDE=1
. rmlib.sh || exit 1

RELEASE=0
BUILD_DATE="$(date +"%F %T %Z")"
BUILD_DATE_PLAIN="$(date +%y%m%d%H%M%S)"
BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"
VERSION="$(rm-version)"
BUILT_PACKAGES=""
BUILT_PKGINFOS=""
BUILT_PKGNAMES=""

function buildall
{
    # $1 = suffix
    # $2 = desc
    
    USEQCC="$(getqcc)"

    echo "#define RM_BUILD_DATE \"$BUILD_DATE ($2)\"" >  "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_NAME \"RocketMinsta$1\""   >> "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_VERSION \"$VERSION\""      >> "$QCSOURCE"/common/rm_auto.qh
    
    if ! [ $SUPPORT_CLIENTPKGS -eq 0 ]; then
        echo "#define RM_SUPPORT_CLIENTPKGS"          >> "$QCSOURCE"/common/rm_auto.qh

        for i in $BUILT_PKGNAMES; do
            echo "#define RM_SUPPORT_PKG_$i"          >> "$QCSOURCE"/common/rm_auto.qh
        done
    fi

    buildqc server/
    mv -v progs.dat "$SVPROGS"

    buildqc client/
    mv -v csprogs.dat "$CSPROGS"

    rm -v "$QCSOURCE"/common/rm_auto.qh
}

function makedata
{
    local rmdata="$1"
    local suffix="$2"
    local desc="$3"
    
    echo " -- Building client-side package $1"
    
    pushd "$rmdata.pk3dir"
    rmdata="zzz-rm-$rmdata"
    
    echo "   -- Calculating md5 sums"
    find -regex "^\./[^_].*" -type f -exec md5sum '{}' \; > _md5sums
    local sum="$(md5sum "_md5sums" | sed -e 's/ .*//g')"
    echo "   -- Writing version info"
    echo "RocketMinsta$2 $VERSION client-side package ($3)" >  _pkginfo_$sum.txt
    echo "Built at $BUILD_DATE"                             >> _pkginfo_$sum.txt
    
    echo "   -- Compressing package"
    7za a -tzip -mfb258 -mpass15 "/tmp/$rmdata-${BUILD_DATE_PLAIN}_tmp.zip" *
    echo "   -- Removing temporary files"
    rm -vf _*
    popd
    
    echo "   -- Installing to $NEXDATA"
    mv -v "/tmp/$rmdata-${BUILD_DATE_PLAIN}_tmp.zip" "$NEXDATA/$rmdata-$sum.pk3"
    echo "   -- Done"
    BUILT_PACKAGES="${BUILT_PACKAGES}$rmdata-$sum.pk3 "
    BUILT_PKGINFOS="${BUILT_PKGINFOS}_pkginfo_$sum.txt "
    BUILT_PKGNAMES="${BUILT_PKGNAMES}$1 "
}

function is-included
{
    if [ $1 = ${1##o_} ] && [ $1 = ${1##c_} ]; then
        # Not a prefixed package, checking if ignored
        for i in $IGNOREPKG; do
            [ $i = $1 ] && return 1;
        done

        return 0;
    fi

    for i in $BUILDPKG_OPTIONAL; do
        [ $i = ${1##o_} ] && return 0;
    done

    for i in $BUILDPKG_CUSTOM; do
        [ $i = ${1##c_} ] && return 0;
    done

    return 1
}

function makedata-all
{
    if [ $SUPPORT_CLIENTPKGS -eq 0 ]; then
        echo "Not building client packages: restricted by configuration"
        return 0
    fi
    
    local suffix="$1"
    local desc="$2"
    
    #ls | grep -P "\.pk3dir/?$" | while read line; do   #damn subshells
    for line in $(ls | grep -P "\.pk3dir/?$"); do
        is-included "$(echo $line | sed -e 's@\.pk3dir/*$@@g')" || continue
        makedata "$(echo $line | sed -e 's@\.pk3dir/*$@@g')" "$suffix" "$desc"
    done
}

function listcustom()
{
    find "$NEXDATA/rm-custom" -name "*.cfg" | while read cfg; do
        echo -e "\t\t$cfg : $(head -1 "$cfg" | sed -e 's@//cfgname:@@')"
    done
}

function finalize-install
{
    cp -v "rocketminsta.cfg" "$NEXDATA"

    if ! [ $SUPPORT_CLIENTPKGS -eq 0 ]; then
        cat rocketminsta_pkgextension.cfg >> "$NEXDATA"/rocketminsta.cfg
        cat <<EOF >>"$NEXDATA"/rocketminsta.cfg
rm_clearpkgs
$(for i in $BUILT_PKGINFOS; do
    echo "rm_putpackage $i"
done)
EOF
    fi

    cat <<EOF >>"$NEXDATA"/rocketminsta.cfg

// Tells the engine to load the mod
set sv_progs $(echo "$SVPROGS" | sed -e 's@.*/@@g')
set csqc_progname $(echo "$CSPROGS" | sed -e 's@.*/@@g')
EOF

    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        mkdir -pv "$NEXDATA/rm-custom"
        cp -v rm-custom/* "$NEXDATA/rm-custom"
    fi
}

################################################################################

[ -e "config.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read configuration"

if [ -z "$SUPPORT_CLIENTPKGS" ]; then
    warn-oldconfig "config.sh" "SUPPORT_CLIENTPKGS" "1"
    SUPPORT_CLIENTPKGS=0
fi

if [ -z $BUILDPKG_OPTIONAL ]; then
    warn-oldconfig "config.sh" "BUILDPKG_OPTIONAL" "(-)"
    BUILDPKG_OPTIONAL=(-)
fi

if [ -z $BUILDPKG_CUSTOM ]; then
    warn-oldconfig "config.sh" "BUILDPKG_CUSTOM" "(-)"
    BUILDPKG_CUSTOM=(-)
fi

if [ -z $IGNOREPKG ]; then
    warn-oldconfig "config.sh" "IGNOREPKG" "(-)"
    IGNOREPKG=(-)
fi

if [ "$1" = "release" ]; then
    RELEASE=1
    
    if [ -n "$2" ]; then
        RELCFG="_$2"
    fi
    
    [ -e "releaseconfig$RELCFG.sh" ] || error "No release configuration file found. Please run \`cp EXAMPLE_releaseconfig.sh releaseconfig$RELCFG.sh', edit releaseconfig$RELCFG.sh and try again."
    . "releaseconfig$RELCFG.sh" || error "Failed to read release configuration"
    
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
    
    if rm-hasversion; then
        RELEASE_PKGNAME="${PKGNAME}_$VERSION"
    else
        RELEASE_PKGNAME="${PKGNAME}_$BUILD_DATE_PLAIN"
    fi
    
    RELEASE_PKGPATH="$(readlink -f "$RELEASE_PKGPATH")"
    mkdir "$RELEASE_PKGPATH/$RELEASE_PKGNAME" || error "Failed to create package directory"

    NEXDATA="$(readlink -f "$RELEASE_PKGPATH/$RELEASE_PKGNAME")"
    SVPROGS="$NEXDATA/$(echo "$SVPROGS" | sed -e 's@.*/@@g')"
    CSPROGS="$NEXDATA/$(echo "$CSPROGS" | sed -e 's@.*/@@g')"

    makedata-all "$RELEASE_REALSUFFIX" "$RELEASE_DESCRIPTION"
    buildall "$RELEASE_REALSUFFIX" "$RELEASE_DESCRIPTION"
    finalize-install    

    if [ -n "$RELEASE_DEFAULTCFG" ]; then
        cat "rm-custom/$RELEASE_DEFAULTCFG.cfg" >> "$NEXDATA/rocketminsta.cfg"
        sed -i "/exec rocketminsta.cfg/d" "$NEXDATA/rocketminsta.cfg" # Without this, a recursive include will occur
    fi
    
    cat <<EOF > "$NEXDATA/README.rmrelease"

This is an auto generated $PKGNAME $VERSION release package, built at $BUILD_DATE. Installation:
    
    1) Extract the contents of this package into your Nexuiz data directory (typically ~/.nexuiz/data/)
    2) Edit your server config and add the following line at very top:
        
        exec rocketminsta.cfg
EOF

    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        cat <<EOF >> "$NEXDATA/README.rmrelease"
        
        If you'd like to use one of the custom configurations,
        add the following at the bottom of your config:
        
            exec rm-custom/NAME_OF_CUSTOM_CONFIG.cfg
        
        The following configurations were included at build time: `ls rm-custom/*.cfg | while read line; do line=${line##rm-custom/}; echo -n "$line "; done`
EOF
    fi

    if [ $SUPPORT_CLIENTPKGS -eq 0 ]; then
        cat <<EOF >> "$NEXDATA/README.rmrelease"
    3) Start the server and enjoy.
EOF
    else
        cat <<EOF >> "$NEXDATA/README.rmrelease"
    3) MAKE SURE that the following packages can be autodownloaded by clients:
        $BUILT_PACKAGES
        
        This package contains all of them
    4) Start the server and enjoy.
EOF
    fi

    cat <<EOF >> "$NEXDATA/README.rmrelease"

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

RELEASE_RMCUSTOM=1
makedata-all -$BRANCH "git build"
buildall -$BRANCH "git build"
finalize-install

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
    line at top of your server config:
    
        exec rocketminsta.cfg

    If you'd like to use one of the custom configurations,
    add the following at the bottom of your config:
        
        exec rm-custom/NAME_OF_CUSTOM_CONFIG.cfg

    (note: if you have sv_progs and csqc_progname variables changed
    because of previous RocketMinsta installation, it's a good idea to remove them)
EOF

    if ! [ $SUPPORT_CLIENTPKGS -eq 0 ]; then
        cat <<EOF
        
    In addition, these packages MUST be available on your download server:
        $BUILT_PACKAGES
    
    All of them have been also installed into:
        $NEXDATA
    
    They will be added to sv_curl_serverpackages automatically.
    If you can't host these packages, please rebuild with SUPPORT_CLIENTPKGS=0
EOF
    fi

cat <<EOF

**************************************************
EOF
