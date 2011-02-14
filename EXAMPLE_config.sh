#!/bin/bash

# Path to your Nexuiz data directory. Typically $HOME/.nexuiz/data
NEXDATA="$HOME/.nexuiz/data"

# Paths where the compiled mod files will be installed
SVPROGS="$NEXDATA/sv_mod.dat"
CSPROGS="$NEXDATA/cl_mod.dat"

# List of QuakeC compillers the script will attempt to use
# Full and relative paths are allowed
QCC=("fteqcc" "qcc" "$HOME/bin/fteqcc" "$HOME/bin/qcc")

# Additional flags to pass to the QuakeC compiller
QCCFLAGS="-O3"

# Where QuakeC source is located
QCSOURCE="qcsrc"
