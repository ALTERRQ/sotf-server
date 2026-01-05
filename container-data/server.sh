#!/usr/bin/env sh

set -e

# Install RedLoader
if [ -f "/data/SonsOfTheForestDS.exe" ]; then
    if [ -d "/data/_RedLoader" ] || [ -d "/data/_Redloader" ]; then
        echo ">>> A Redloader version is already installed"
    else
        echo ">>> Downloading and unpacking RedLoader.zip (version: $REDLOADER_VERSION)"
        wget -qO /data/RedLoader.zip "https://github.com/ToniMacaroni/RedLoader/releases/download/$REDLOADER_VERSION/RedLoader.zip"
        unzip -qo /data/RedLoader.zip
        rm /data/RedLoader.zip
        echo ">>> Redloader $REDLOADER_VERSION installed"
    fi
else
    echo ">>> Skipping: The game is not yet installed"
fi

LOG_FILE="$SERVER_CONFIG_DIR/game_server.log"
RAW_LOG_FILE="$SERVER_CONFIG_DIR/game_server_raw.log"

if [ "$FILTER_SHADER_AND_MESH_AND_WINE_DEBUG" = "true" ]; then
    # Save raw output, save and show filtered output + quick fix for redloader issue from V0.8.0 and above
    script -q -c "WINEDEBUG=-all stdbuf -oL -eL wine SonsOfTheForestDS.exe -userdatapath \"$SERVER_CONFIG_DIR\"" /dev/null 2>&1 | \
    tee "$RAW_LOG_FILE" | \
    stdbuf -oL grep -v -E ".*WARNING: Shader.*|.*ERROR: Shader.*|.*No mesh data available for mesh.*|.*Couldn't create a Convex Mesh from source.*|.*The referenced script.*|.*Could not find video decode shader pass.*" | \
    tee "$LOG_FILE"
else
    # Save and show all output + quick fix for redloader issue from V0.8.0 and above
    script -q -c "wine SonsOfTheForestDS.exe -userdatapath \"$SERVER_CONFIG_DIR\"" /dev/null 2>&1 | tee "$LOG_FILE"
fi
