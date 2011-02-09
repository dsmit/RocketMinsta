#!/bin/bash

NEXDATA="$HOME/.nexuiz/data"

# These must match sv_progs and csqc_progname values
SVPROGS="$NEXDATA/sv_mod.dat"
CSPROGS="$NEXDATA/cl_mod.dat"

# List of QuakeC compillers the script will attempt to use
# Full and relative paths are allowed
QCC=("fteqcc" "qcc" "$HOME/bin/fteqcc" "$HOME/bin/qcc")

# Additional flags to pass to the QuakeC compiller
QCCFLAGS="-O3"

# Where QuakeC source is located
QCSOURCE="qcsrc"

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

USEQCC="$(getqcc)"

function buildqc
{
    qcdir="$QCSOURCE/$1"

    echo " -- Building $qcdir" >&2
    pushd "$qcdir" &>/dev/null || error "Build target does not exist? huh"
    $USEQCC $QCCFLAGS || error "Failed to build $qcdir"
    popd &>/dev/null
}

buildqc server/
mv -v progs.dat "$SVPROGS"

buildqc client/
mv -v csprogs.dat "$CSPROGS"

