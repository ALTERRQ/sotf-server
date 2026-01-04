#!/usr/bin/env sh

set -e

# Install RedLoader
if [ -f "/data/SonsOfTheForestDS.exe" ]; then
    if [ ! -d "/data/_RedLoader" ]; then
        echo ">>> Downloading and unpacking RedLoader.zip (version: $REDLOADER_VERSION)"
        wget -qO /data/RedLoader.zip "https://github.com/ToniMacaroni/RedLoader/releases/download/$REDLOADER_VERSION/RedLoader.zip"
        unzip -qo /data/RedLoader.zip
        rm /data/RedLoader.zip
        echo ">>> Redloader $REDLOADER_VERSION installed"
    else
        echo ">>> Redloader $REDLOADER_VERSION is already installed"
    fi
else
    echo ">>> Skipping: The game is not yet installed"
fi

# Launch and check if log filtering is enabled
if [ "$FILTER_SHADER_AND_MESH_AND_WINE_DEBUG" = "true" ]; then
    # Start the server without output buffering and pipe through grep to filter out shader warnings + log without filtering
    WINEDEBUG=-all stdbuf -oL -eL wine SonsOfTheForestDS.exe -userdatapath $SERVER_CONFIG_DIR 2>&1 | \
    tee "$SERVER_CONFIG_DIR/game_server.log" | \
    stdbuf -oL grep -v -E ".*WARNING: Shader.*|.*ERROR: Shader.*|.*No mesh data available for mesh.*|.*Couldn't create a Convex Mesh from source.*|.*The referenced script.*|.*Could not find video decode shader pass.*"
else
    wine SonsOfTheForestDS.exe -userdatapath $SERVER_CONFIG_DIR 2>&1 | tee "$SERVER_CONFIG_DIR/game_server.log"
fi
