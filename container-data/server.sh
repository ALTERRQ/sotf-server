#!/usr/bin/env sh

set -e

if [ "$FILTER_SHADER_AND_MESH_AND_WINE_DEBUG" = "true" ]; then
    # Start the server without output buffering and pipe through grep to filter out shader warnings
    stdbuf -oL -eL wine SonsOfTheForestDS.exe -userdatapath $SERVER_CONFIG_DIR 2>&1 | \
    stdbuf -oL grep -v -E ".*WARNING: Shader.*|.*ERROR: Shader.*|.*No mesh data available for mesh.*|.*Couldn't create a Convex Mesh from source.*|.*The referenced script.*|.*Could not find video decode shader pass.*"
else
    wine SonsOfTheForestDS.exe -userdatapath $SERVER_CONFIG_DIR
fi
