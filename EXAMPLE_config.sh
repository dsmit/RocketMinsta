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

# Whether to build client-side packages and enable support for them in the mod
# Disable ONLY if you, for any reason, have no way of letting clients download those packages automatically.
SUPPORT_CLIENTPKGS=1

# A list of optional client packages to build.
# These packages are a part of RocketMinsta, but aren't built automatically. They have a prefix of "o_".
# Do NOT put the prefix here (to include o_derp.pk3dir, just put 'derp'). The syntax is the same as of the QCC array
BUILDPKG_OPTIONAL=(-)

# A list of custom client packages to build.
# These packages act just like optional packages, except they are not a part of RocketMinsta and are ignored by git
# They have a prefix of "c_". 
BUILDPKG_CUSTOM=(-)

# A list of client packages that will NOT be built
# These are packages WITHOUT o_ or c_ prefixes, do not touch this option unless you really know what are you doing
IGNOREPKG=(-)

# If this option is enabled, built packages will be stored and referenced later when you rebuild the mod,
# to save time by not rebuilding the same package over and over again. But if you made changes to the package,
# it will be, of course, rebuilt. This option is only useful if you're a developer who constantly needs to rebuild the mod
CACHEPKGS=0

