#!/bin/bash

# Script to update/add startup parameters with validation
# Usage: ./update_parameter.sh <key> <value>

set -e

# Check if correct number of arguments
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments"
    echo "Usage: $0 <key> <value>"
    exit 1
fi

KEY="$1"
VALUE="$2"

GAME_INFO_FILE="/home/lgsm/blazor_lgsm/scripts/game_info.json"
STARTUP_PARAMS_FILE="/home/lgsm/blazor_lgsm/user_startup_parameters.json"

# Check if game_info.json exists
if [ ! -f "$GAME_INFO_FILE" ]; then
    echo "Error: Game info file not found: $GAME_INFO_FILE"
    exit 1
fi

# Check if startup_parameters.json exists, if not create empty array
if [ ! -f "$STARTUP_PARAMS_FILE" ]; then
    echo "Creating startup parameters file: $STARTUP_PARAMS_FILE"
    echo "[]" > "$STARTUP_PARAMS_FILE"
    chmod 755 $STARTUP_PARAMS_FILE
fi

# Validate key exists in game_info.json parameters
KEY_EXISTS=$(jq -r --arg key "$KEY" '.parameters[] | select(.key == $key) | .key' "$GAME_INFO_FILE")

if [ -z "$KEY_EXISTS" ]; then
    echo "Error: Key '$KEY' not found in game_info.json parameters"
    exit 1
fi

# Check if parameter is editable (check .editable directly, not .allowed.editable)
IS_EDITABLE=$(jq -r --arg key "$KEY" '.parameters[] | select(.key == $key) | .editable // false' "$GAME_INFO_FILE")

if [ "$IS_EDITABLE" != "true" ]; then
    echo "Error: Parameter '$KEY' is not editable (editable != true)"
    exit 1
fi

# Update or add the key/value pair in startup_parameters.json
# Check if key already exists
KEY_INDEX=$(jq --arg key "$KEY" 'map(.key == $key) | index(true)' "$STARTUP_PARAMS_FILE")

if [ "$KEY_INDEX" != "null" ]; then
    # Update existing key
    jq --arg key "$KEY" --arg value "$VALUE" \
        'map(if .key == $key then .value = $value else . end)' \
        "$STARTUP_PARAMS_FILE" > "${STARTUP_PARAMS_FILE}.tmp"
    echo "Updated parameter: $KEY = $VALUE"
else
    # Add new key/value pair
    jq --arg key "$KEY" --arg value "$VALUE" \
        '. += [{"key": $key, "value": $value}]' \
        "$STARTUP_PARAMS_FILE" > "${STARTUP_PARAMS_FILE}.tmp"
    echo "Added new parameter: $KEY = $VALUE"
fi

# Move temp file to actual file
mv "${STARTUP_PARAMS_FILE}.tmp" "$STARTUP_PARAMS_FILE"

echo "Success: Parameter updated in $STARTUP_PARAMS_FILE"
exit 0