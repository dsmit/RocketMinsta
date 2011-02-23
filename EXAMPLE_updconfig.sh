#!/bin/bash

# Unless RCON_ADDRESS is left blank, the script will try to use RCON to reload 
# the server config and restart the map after a successful update.
# Note: secure RCON is not supported

RCON_ADDRESS="localhost"
RCON_PORT=26000
RCON_PASSWORD="hackme"

# Commands to run after a successful build
RCON_COMMANDS=(
    "say ^1The match will be interrupted due to an automatic update of the mod"
    "exec server.cfg"
    "endmatch"
)
